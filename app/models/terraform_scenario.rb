require 'open3'

class TerraformScenario

  def initialize(scenario)
    @scenario = scenario
  end

  attr_reader :scenario

  def logger
    Rails.logger
  end

  def data_dir
    Rails.root.join('data', 'scenarios', scenario.uuid)
  end

  def source_dir
    scenario.path
  end

  def variables_file
    data_dir.join('variables.auto.tfvars.json')
  end

  class TerraformError < StandardError

  end

  def run cmd
    Open3.popen3(cmd, chdir: data_dir) do |stdin, stdout, stderr, p|
      stdout.each do |line|
        logger.debug(line.chop)
      end
      stderr.each do |line|
        logger.warn(line.chop)
      end
      if !p.value.success? then
        raise TerraformError.new("exit status was #{p.value.exitstatus}")
      end
    end
  end

  def init!
    data_dir.mkdir unless data_dir.exist?
    run "terraform init -input=false -no-color #{source_dir}"
  end

  def apply!
    data_dir.mkpath unless data_dir.exist?
    variables_file.write(JSON.pretty_generate(TerraformScenario.serialize_scenario(scenario)))
    run "terraform apply -input=false -auto-approve -no-color #{source_dir}"
  end

  def destroy!
    if data_dir.exist?
      run "terraform destroy -input=false -auto-approve -no-color #{source_dir}"
    end
  end

  def output!
    stdout, status = Open3.capture2('terraform output -json -no-color', chdir: data_dir)
    if status.success? then
      output = JSON.parse(stdout)
      self.update_scenario!(output)
    else
      raise TerraformError.new("terraform output failed: exit status was #{status.exitstatus}")
    end
  end

  def clean!
    data_dir.rmtree if data_dir.exist?
  end

  def update_scenario! output
    if output['instances'] then
      output["instances"]["value"].each do |hash|
        instance = scenario.instances.find_by_name!(hash['name'])
        instance.update_attributes!(hash)
      end
    end
  end

  # Inputs are passed to terraform via a json file.
  # It would be nice if someday this format was the same as is used for parshing the yaml files.
  def self.serialize_player(player)
    {
      login: player.login,
      password: {
        plaintext: player.password,
        hash: player.password_hash
      },
      variables: TerraformScenario.serialize_variables(player.variables)
    }
  end

  def self.serialize_group(group)
    h = Hash.new
    h[group.name.downcase] = group.players.map{|p| TerraformScenario.serialize_player(p) }
    h
  end

  def self.serialize_variables(vs)
    h = Hash.new
    vs.each do |v|
      h.merge!(TerraformScenario.serialize_variable(v))
    end
    h
  end

  def self.serialize_variable(variable)
    h = Hash.new
    if variable.password? then
      h[variable.name] = {
        plaintext: variable.value,
        hash: UnixCrypt::SHA512.build(variable.value)
      }
    else
      h[variable.name] = variable.value
    end
    h
  end

  def self.serialize_scenario(scenario)
    h = {
      scenario_id:           scenario.uuid,
      owner:                 scenario.owner.email,
      environment:           Rails.env,
      variables:             TerraformScenario.serialize_variables(scenario.variables)
    }
    scenario.groups.each do |g|
      h.merge!(TerraformScenario.serialize_group(g))
    end
    h
  end

end
