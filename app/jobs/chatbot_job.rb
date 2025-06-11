require 'json'
class ChatbotJob < ApplicationJob
  queue_as :default

  def perform(question)
    @question = question
    chatgpt_response = client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: questions_formatted_for_openai,
        functions: [
          {
            name: "recommend_movies",
            description: "Suggest 3 movies with explanations based on user's favorite movies and question",
            parameters: {
              type: "object",
              properties: {
                suggestions: {
                  type: "array",
                  items: {
                    type: "object",
                    properties: {
                      movie_name: { type: "string" },
                      response_content: { type: "string" }
                    },
                    required: ["movie_name", "response_content"]
                  }
                }
              },
              required: ["suggestions"]
            }
          }
        ],
        function_call: { name: "recommend_movies" }
      }
    )

    # extract the function call arguments and parse the JSON
    function_call = chatgpt_response.dig("choices", 0, "message", "function_call")
    args_json      = function_call["arguments"] || "{}"
    result         = JSON.parse(args_json)
    question.update(ai_answer: args_json)

    # Kick off a TMDb lookup + SaveMovieJob for each suggested movie name
    (result["suggestions"] || []).each do |suggestion|
      SearchMovieByNameJob.perform_later(
        suggestion["movie_name"])

      # append the explanation now into the chat
      Turbo::StreamsChannel.broadcast_append_to(
        "question_#{@question.id}",
        target:  "question_#{@question.id}",
        partial: "questions/suggestion",
        locals:  { suggestion: suggestion }
      )
    end
    # Then update the question header…
    Turbo::StreamsChannel.broadcast_update_to(
      "question_#{@question.id}",
      target: dom_id(@question),
      partial: "questions/question",
      locals: { question: @question }
    )

    # store the raw JSON into ai_answer (or adapt to your model)
    # question.update(ai_answer: args_json)
    # @question.update(ai_answer: args_json)
  end

  private

  def client
    @client ||= OpenAI::Client.new
  end

  private

  def questions_formatted_for_openai
    questions = @question.user.questions
    results = []

    system_text = "You are an assistant for an movie website. 1. Always say the name of the Movie. 2. If you don't know the answer, you can say 'I don't know. If you don't have any movies at the end of this message, say we don't have that.  Here are the movies you should use to answer the user's questions: "
    # to nearest_products code as private method

    nearest_movies.each do |movie|
      system_text += "** MOVIE #{movie.id}: name: #{movie.title}, description: #{movie.overview} **"
    end
    results << { role: "system", content: system_text }

    questions.each do |question|
      results << { role: "user", content: question.user_question }
      results << { role: "assistant", content: question.ai_answer || "" }
    end

    return results
  end

  def nearest_movies
    response = client.embeddings(
      parameters: {
        model: 'text-embedding-3-small',
        input: @question.user_question
      }
    )
    question_embedding = response['data'][0]['embedding']
    return Movie.nearest_neighbors(
      :embedding, question_embedding,
      distance: "euclidean"
    )
    # you may want to add .first(3) here to limit the number of results
  end
end
