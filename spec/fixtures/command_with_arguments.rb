command :echo, arguments: [{ text: "" }, author: nil] do |**params|
  say params[:author] ? "#{params[:author]}: #{params[:text]}" : params[:text]
end
