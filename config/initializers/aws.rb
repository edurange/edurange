if Rails.configuration.x.provider == 'aws'
  # test for correct environment variables
  def mask secret
      secret.length > 4 ? '*' * (secret.length - 4) + secret[-4, 4] : secret
  end
  if !ENV['AWS_ACCESS_KEY_ID'] or !ENV['AWS_SECRET_ACCESS_KEY'] or !ENV['AWS_REGION']
      puts "\nThe following Aws required environment variables are missing:\n\n"
      puts "AWS_ACCESS_KEY_ID" if not ENV['AWS_ACCESS_KEY_ID']
      puts "AWS_SECRET_ACCESS_KEY" if not ENV['AWS_SECRET_ACCESS_KEY']
      puts "AWS_REGION" if not ENV['AWS_REGION']
  else
      puts "\nUsing the following AWS configuration:\n\n"
      puts "AWS_ACCESS_KEY_ID=#{ENV['AWS_ACCESS_KEY_ID']}"
      puts "AWS_SECRET_ACCESS_KEY=#{mask ENV['AWS_SECRET_ACCESS_KEY']}"
      puts "AWS_REGION=#{ENV['AWS_REGION']}"
  end
end
