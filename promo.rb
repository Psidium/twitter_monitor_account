require 'twitter'
require 'json'

if !ARGV[0]
  puts 'Usage: ruby promo.rb account_to_monitor'
  puts 'withOUT the @, only the nick'
  exit
end

bot_name = "GBF_Gabriel"
case bot_name
when "GBF_Gabriel"
  @client = Twitter::REST::Client.new do |config|
    config.consumer_key        = 'myYVTEQG00UCHslybO5qxY8QP' #I've just revoked thoose, use your own twitter profile
    config.consumer_secret     = 'UTG1m77NWaS2EijN4KKjBvmW7kTq7x8n4H2EcFS5X2lLSOUqq5'
    config.access_token        = '1064877108-a3DEIJzZ6BgkOQemSU9u1HZHqkSMiDDJ8slSqt4'
    config.access_token_secret = 'S4xPqH3VA1lL64GL6uNNwglAUII1eB1f9tJsRN7fFuPMH'
  end

  streaming = Twitter::Streaming::Client.new do |config|
    config.consumer_key        = 'myYVTEQG00UCHslybO5qxY8QP'
    config.consumer_secret     = 'UTG1m77NWaS2EijN4KKjBvmW7kTq7x8n4H2EcFS5X2lLSOUqq5'
    config.access_token        = '1064877108-a3DEIJzZ6BgkOQemSU9u1HZHqkSMiDDJ8slSqt4'
    config.access_token_secret = 'S4xPqH3VA1lL64GL6uNNwglAUII1eB1f9tJsRN7fFuPMH'
  end
when "Psiidium"
  @client = Twitter::REST::Client.new do |config|
    config.consumer_key        = 'w95t1CmkoaDfLrWUbXjqgg'
    config.consumer_secret     = 'jI2UCpZZw6Pm1Qgqozr176Vh44dKCIpfWUQOnRwkiQ'
    config.access_token        = '143255657-tkF3sloYreEw7rPkVJpTed7kzHAQZAc4IwmfbFSW'
    config.access_token_secret = 'hxzSKECZH7WcqOLdzaaOnR4UPuY6SJreFjcJpbFklGNuT'
  end

  streaming = Twitter::Streaming::Client.new do |config|
    config.consumer_key        = 'w95t1CmkoaDfLrWUbXjqgg'
    config.consumer_secret     = 'jI2UCpZZw6Pm1Qgqozr176Vh44dKCIpfWUQOnRwkiQ'
    config.access_token        = '143255657-tkF3sloYreEw7rPkVJpTed7kzHAQZAc4IwmfbFSW'
    config.access_token_secret = 'hxzSKECZH7WcqOLdzaaOnR4UPuY6SJreFjcJpbFklGNuT'
  end
end

@filename = "./keywords.json"
begin
  fileKey = File.open(@filename, "r+")
  @keywords = JSON.parse(fileKey.read) #keeps in memory and uses disk for backup only
  fileKey.close
rescue
  fileKey = File.new(@filename, "w+")
  fileKey.close
  @keywords = Hash.new { |hash, key| hash[key] = [] }
end

def refresh_keyword_file
  fileKey = File.open(@filename, "r+")
  fileKey.rewind
  fileKey.write(@keywords.to_json)
  fileKey.close
end

def newHardmob tweet
  hardmob_text = tweet.full_text
  @keywords.each do |key, array|
    puts "procurando pelas coisas que o #{key} quer (dica, é #{array})"
    array.each do |monitor|
      puts "sera que #{hardmob_text} tem #{monitor}?"
      if !monitor.is_a? String
        warn 'EPA PORRA QUE NA ITERACAO DA LAPADA DAS AVES RARAS N É STRING'
        puts 'tem la dentro é ' + monitor.to_s + 'e up tem o que ' + array.to_s
      end
      if hardmob_text.downcase.include? monitor.downcase
        puts 'TEM SIM'
        dm_text = "Hardmob postou \"#{monitor}\""
        dm_final = "#{tweet.uri} #{dm_text[0,100]}"
        puts "antes de chamar é #{tweet.uri}"
        @client.create_direct_message(key, dm_final)
        puts "saiu no fim a dm: #{dm_final} link deve ser: #{tweet.uri}"
      end
    end
  end
end

def returnDmAlways(screen_name, msg)
  begin
    puts 'vai mandar a dm'
    @client.create_direct_message(screen_name, msg)
  rescue Twitter::Error::Forbidden
    puts 'pegou forbidden, tentando de novo'
    returnDmAlways(screen_name, msg + '.')
  rescue Twitter::Error::TooManyRequests
    puts 'too many requests, vou dormir por ' + error.rate_limit.reset
    sleep error.rate_limit.reset_in + 1
  end
end

def incomingCommand dm
  puts "entrou dm escrita #{dm.text}"
  case dm.text
  when /^(monitore )/i
    puts 'identificado monitore'
    new_word = dm.text[9..-1]
    @keywords[dm.sender.screen_name].push(new_word)
    refresh_keyword_file
    reply = "#{new_word} adicionado"
  when /^(delete )/i
    puts 'identificado delete'
    old_word = dm.text[7..-1]
    if @keywords[dm.sender.screen_name].include? old_word
      @keywords[dm.sender.screen_name] -= [old_word]
      refresh_keyword_file
      reply = "#{old_word} removido com sucesso"
    else
      reply = "#{old_word} nao foi encontrado"
    end
  when /^(liste)/i
    puts 'identificado liste'
    returnDmAlways(dm.sender.screen_name, 'Os monitoramentos ativos são os seguintes:')
    if @keywords[dm.sender.screen_name]
      @keywords[dm.sender.screen_name].each do |monitor|
         returnDmAlways(dm.sender.screen_name, monitor)
      end
    end
    reply = 'Fim da listagem do monitoramento'
  when /^(ajuda)/i
    puts 'identificado ajuda'
    reply = 'Comandos: "monitora frase","delete frase", "liste".'
  else
    puts 'nao encontrou nada'
    reply = 'Comando não reconhecido (tente "ajuda")'
  end
  if reply
    puts 'tenta mandar a dm'
    returnDmAlways(dm.sender.screen_name, reply)
  end
end


begin
  screen_name_meu = @client.user.screen_name
rescue
  screen_name_meu = 'Psiidium' #por favor SÓ NO DEBUG O MERDA
end

streaming.user do |object|
  case object
  when Twitter::Tweet
    if ARGV[0] == object.user.screen_name
      puts "conta monitorada tweetou"
      newHardmob object
    end
  when Twitter::DirectMessage
    if screen_name_meu != object.sender.screen_name
      puts "entrou dm"
      incomingCommand object
    end
  when Twitter::Streaming::StallWarning
    warn 'Falling behind!'
  end
end
