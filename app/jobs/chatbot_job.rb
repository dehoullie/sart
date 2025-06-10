class ChatbotJob < ApplicationJob
  queue_as :default

  def perform(question)
    @question = question
    chatgpt_response = client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: questions_formatted_for_openai # to code as private method
      }
    )

    new_content = chatgpt_response["choices"][0]["message"]["content"]
    question.update(ai_answer: new_content)
    Turbo::StreamsChannel.broadcast_update_to(
      "question_#{@question.id}",
      target: "question_#{@question.id}",
      partial: "questions/question", locals: { question: question })
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
