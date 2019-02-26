

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

  # get iam user name and set some aws configs
  Rails.configuration.x.aws['iam_user_name'] = AWS::IAM::Client.new.get_user.user.user_name
  Rails.configuration.x.aws['s3_bucket_name'] = "edurange-" + Rails.configuration.x.aws['iam_user_name']
  Rails.configuration.x.aws['ec2_key_pair_name'] = "#{Rails.configuration.x.aws['iam_user_name']}-#{Rails.configuration.x.aws['region']}"

  # create keypair if it doesn't already exist
  aws_key_pair_path = "#{Rails.root}/keys/#{Rails.configuration.x.aws['ec2_key_pair_name']}"
  FileUtils.mkdir("#{Rails.root}/keys") if not File.exists?("#{Rails.root}/keys")
  if not File.exists?(aws_key_pair_path)
    begin
      aws_key_pair = AWS::EC2::Client.new.create_key_pair(key_name: Rails.configuration.x.aws['ec2_key_pair_name'])
      File.open(aws_key_pair_path, "w") { |f| f.write(aws_key_pair[:key_material]) }
      FileUtils.chmod(0400, aws_key_pair_path)
    rescue
    end
  end

end

