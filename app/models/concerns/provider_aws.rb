# This file contains the implementation of the AWS API calls. They are implemented
# as hooks, called dynamically by the {Provider} concern when {Scenario}, {Cloud}, {Subnet}, and {Instance} are booted.
# @see Provider#boot
require 'active_support'
module ProviderAws
  extend ActiveSupport::Concern

  # Cloud

  def aws_cloud_boot
    raise RuntimeError, 'driver id already set' if self.driver_id != nil

    # create VPC
    log "AWS: creating VPC"
    vpc = aws_call('aws_vpc_create')
    log "AWS: created VPC '#{vpc.id}'"
    self.update_attribute(:driver_id, vpc.id)

    # wait for VPC to become available
    aws_obj_wait_till_available(vpc)

    # create VPC tags
    aws_obj_tags_default(vpc)

    # create Internet Gateway
    log "AWS: creating InternetGateway"
    internet_gateway = aws_call('aws_internet_gateway_create', vpc: vpc)
    log "AWS: created InternetGateway '#{internet_gateway.id}'"

    # get VPC security group
    log "AWS: getting VPC '#{vpc.id}' SecurityGroup"
    security_group = aws_call('aws_vpc_security_group_get', vpc: vpc)

    # create default routing rules
    log "AWS: creating rules for SecurityGroup '#{security_group.id}'"
    aws_call('aws_security_group_enable_inbound', security_group: security_group)
    aws_call('aws_security_group_disable_outbound', security_group: security_group)
    aws_call('aws_security_group_enable_outbound_port_80', security_group: security_group)
    aws_call('aws_security_group_enable_outbound_port_443', security_group: security_group)
    aws_call('aws_security_group_enable_outbound_to_subnets', security_group: security_group)
  end

  def aws_cloud_unboot
    # get VPC
    log "AWS: getting VPC '#{self.driver_id}'"
    begin
      vpc = aws_call('aws_vpc_get', vpc_id: self.driver_id, errs: { AWS::EC2::Errors::InvalidVpcID::NotFound => 120})
    rescue AWS::EC2::Errors::InvalidVpcID::NotFound => e
      log "AWS: could not find VPC '#{self.driver_id}' abandoning VPC"
      self.update_attribute(:driver_id, nil)
      return
    end

    if not aws_call('aws_obj_exists?', obj: vpc)
      log "AWS: VPC '#{self.driver_id}' does not exist abandoning VPC"
      self.update_attribute(:driver_id, nil)
      return
    end

    # get VPC InternetGateway detach and delete
    log "AWS: getting VPC '#{vpc.id}' InternetGateway"
    if internet_gateway = aws_call('aws_vpc_internet_gateway_get', vpc: vpc)
      log "AWS: checking if InternetGateway '#{internet_gateway.id}' exists"
      if aws_call('aws_obj_exists?', obj: internet_gateway)
        
        log "AWS: detaching InternetGateway '#{internet_gateway.id}'"
        aws_call('aws_internet_gateway_vpc_detach', vpc: vpc, internet_gateway: internet_gateway)
        
        log "AWS: deleting InternetGateway '#{internet_gateway.id}'"
        aws_call('aws_obj_delete', obj: internet_gateway)
      end
    end

    # delete VPC NetworkACLs
    log "AWS: getting VPC '#{vpc.id}' NetworkACL's"
    aws_call('aws_vcp_network_acls_get', vpc: vpc).each do |network_acl|
      
      log "AWS: deleting NetworkACL '#{network_acl.id}'"
      aws_call('aws_obj_delete', obj: network_acl)
    end

    # delete VPC SecurityGroups
    log "AWS: getting VPC '#{vpc.id}' SecurityGroups"
    aws_call('aws_vpc_security_groups_get', vpc: vpc).each do |security_group|
      
      log "AWS: deleting SecurityGroup '#{security_group.id}'"
      aws_call('aws_obj_delete', obj: security_group)
    end

    # delete VPC RouteTables
    log "AWS: getting VPC '#{vpc.id}' RouteTables"
    aws_call('aws_vpc_route_tables_get', vpc: vpc).each do |route_table|
      
      log "AWS: deleting RouteTable '#{route_table.id}'"
      aws_call('aws_obj_delete', obj: route_table)
    end

    # delete VPC
    log "AWS: deleting VPC '#{vpc.id}'"
    aws_call('aws_obj_delete', obj: vpc, errs: {AWS::EC2::Errors::DependencyViolation => 60})
    self.update_attribute(:driver_id, nil)
  end

  # Subnet

  def aws_subnet_boot
    raise 'AWS: driver id already set' if self.driver_id != nil
    
    # create Subnet
    log "AWS: creating Subnet"
    subnet = aws_call(
      'aws_subnet_create', 
      cidr_block: self.cidr_block, 
      vpc_id: self.cloud.driver_id)
    self.update_attribute(:driver_id, subnet.id)
    log "AWS: created Subnet '#{subnet.id}'"

    # wait till Subnet becomes available
    log "AWS: waiting for Subnet '#{subnet.id}' to become available"
    aws_obj_wait_till_available(subnet)

    # create default tags
    aws_obj_tags_default(subnet)

    # create RouteTable
    log "AWS: creating RouteTable for '#{subnet.id}'"
    route_table = aws_call('aws_vpc_route_table_create', vpc_id: self.cloud.driver_id)

    # assing RouteTable to Subnet
    log "AWS: assigned RouteTable '#{route_table.id}' to '#{subnet.id}'"
    aws_call('aws_route_table_subnet_assign', subnet: subnet, route_table: route_table)

    # get Subnet's VPC
    log "AWS: getting Subnet '#{subnet.id}' VPC '#{self.cloud.driver_id}'"
    vpc = aws_call('aws_vpc_get', vpc_id: self.cloud.driver_id)

    if self.internet_accessible
      # get Subnet VPC InternetGateway
      internet_gateway = aws_call('aws_vpc_internet_gateway_get', vpc: vpc)

      # make route in route table to InternetGateway
      aws_call('aws_route_table_internet_gateway_route_create', route_table: route_table, internet_gateway: internet_gateway)
    else
      # create route to NAT
      if nat = self.scenario.nat_instance
        if nat.driver_id
          aws_call(
            'aws_route_table_instance_route_create', 
            route_table: route_table, 
            instance_id: nat.driver_id,
            errs: { AWS::EC2::Errors::MissingParameter => 60 }
          )
        end
      end
    end
  end

  def aws_subnet_unboot
    raise RuntimeError, 'not driver id set' if self.driver_id == nil

    log "AWS: getting Subnet '#{self.driver_id}'"
    begin
      subnet = aws_call('aws_subnet_get', subnet_id: self.driver_id, errs: { AWS::EC2::Errors::InvalidSubnetID::NotFound => 120 })
    rescue AWS::EC2::Errors::InvalidSubnetID::NotFound => e
      log "AWS: could not find Subnet '#{self.driver_id}' abandoning Subnet"
      self.update_attribute(:driver_id, nil)
      return
    end

    log "AWS: getting Subnet '#{self.driver_id}' RouteTableAssociation"
    begin
      route_table_association = aws_call('aws_subnet_route_table_association_get', subnet: subnet)
    rescue AWS::EC2::Errors::InvalidSubnetID::NotFound => e
      log "AWS: could not find Subnet '#{self.driver_id}' abandoning Subnet"
      self.update_attribute(:driver_id, nil)
      return
    end

    if not route_table_association.main?
      log "AWS: deleting RouteTableAssociation '#{route_table_association.id}'"
      aws_call('aws_obj_delete', obj: route_table_association)
    end

    log "AWS: deleting Subnet '#{self.driver_id}'"
    aws_call('aws_obj_delete', obj: subnet, errs: {AWS::EC2::Errors::DependencyViolation => 60} )
    self.update_attribute(:driver_id, nil)
  end

  # Instance

  def aws_instance_boot
    raise 'AWS: driver id already set' if self.driver_id != nil

    aws_instance_S3_files_create

    log "AWS: creating Instance"
    instance = aws_call(
      'aws_instance_create',
      errs: { AWS::EC2::Errors::InvalidSubnetID::NotFound => 60 }
    )
    self.update_attribute(:driver_id, instance.id)
    log "AWS: created Instance '#{instance.id}'"

    aws_instance_wait_till_status_equals(instance, :running, 60*10)

    aws_obj_tags_default(instance)

    aws_instance_elastic_ip_create(instance) if self.internet_accessible

    aws_call('aws_instance_network_interface_first_source_dest_check_disable', instance: instance)

    aws_instance_create_route_to_nat(instance) if self.os == 'nat'
  end

  def aws_instance_unboot
    if self.driver_id == nil
      raise 'AWS: no driver id' if not aws_instance_S3_files_delete
    end

    log "AWS: getting Instance '#{self.driver_id}'"
    instance = aws_call('aws_instance_get', instance_id: self.driver_id)

    log "AWS: checking if Instance '#{instance.id}' exists"
    if aws_call('aws_obj_exists?', obj: instance)

      log "AWS: looking for Instance '#{self.driver_id}' ElasticIP" if self.internet_accessible
      if elastic_ip = aws_call('aws_instance_elastic_ip_get', instance: instance)
        log "AWS: disassociating ElasticIP '#{elastic_ip.public_ip}'"
        aws_call('aws_instance_elastic_ip_disassociate', instance: instance)

        log "AWS: deleting ElasticIP '#{elastic_ip.public_ip}'"
        aws_call('aws_obj_delete', obj: elastic_ip)

        self.update_attribute(:ip_address_public, nil)
      end

      aws_instance_volumes_delete_on_termination_set(instance)

      log "AWS: deleting Instance '#{instance.id}'"
      aws_call('aws_obj_delete', obj: instance)
      self.update_attribute(:driver_id, nil)

      aws_instance_wait_till_status_equals(instance, :terminated, 360)
    else
      log "AWS: Instance '#{self.driver_id}' does not exist abandoning driver id"
    end

    aws_instance_S3_files_save
    self.scenario.statistic.data_process

    aws_instance_S3_files_delete
  end

  def aws_instance_wait_till_status_equals(obj, status, time)
    log "AWS: waiting for #{obj.class.to_s.split("::").last} '#{obj.id}' status to change to ':#{status}'"
    begin
      Timeout.timeout(time) do 
        sleep 1 while aws_call(
          'aws_instance_status', 
          instance: obj,
          errs: { AWS::EC2::Errors::InvalidInstanceID::NotFound => 60 }
        ) != status
      end
    rescue Timeout::Error => e
      raise "AWS: timeout while waiting for #{obj.class.to_s.split("::").last} '#{obj.id} status to change to ':#{status}'"
    end
  end

  def aws_instance_elastic_ip_create(instance)
    log "AWS: creating ElasticIP for Instance '#{instance.id}'"
    elastic_ip = aws_call('aws_elastic_ip_create')
    log "AWS: created ElasticIP '#{elastic_ip.public_ip}'"

    log "AWS: waiting for ElasticIP '#{elastic_ip.public_ip}' to exist"
    Timeout.timeout(360) { sleep 1 while not aws_call('aws_obj_exists?', obj: elastic_ip) }

    log "AWS: associating ElastipIP '#{elastic_ip.public_ip}' with Instance '#{instance.id}'"
    aws_call(
      'aws_instance_elastic_ip_associate',
      instance: instance,
      elastic_ip: elastic_ip,
      errs: { AWS::EC2::Errors::InvalidAllocationID::NotFound => 60 }
    )
  
    self.update_attribute(:ip_address_public, elastic_ip.public_ip)
  end

  def aws_instance_volumes_delete_on_termination_set(instance)
    log "AWS: setting Instance '#{self.driver_id}' volumes deleteOnTermination"
    aws_call('aws_instance_block_devices_get', instance: instance).each do |block_device|
      aws_call('aws_instance_block_device_ebs_delete_on_termination_set', instance: instance, block_device: block_device)
    end
  end

  def aws_instance_create_route_to_nat(instance)
    log "AWS: creating Route for Subnet '#{self.subnet.driver_id}' to NAT Instance '#{self.driver_id}'"
    self.scenario.subnets.select { |s| s.driver_id and !s.internet_accessible }.each do |subnet|
      aws_call('aws_subnet_route_table_route_to_nat_create', subnet_id: subnet.driver_id, instance_id: instance.id)
    end
  end

  def aws_instance_S3_files_save
    time = Time.now.strftime("%y_%m_%d")
    bucket = aws_call('aws_S3_bucket_get', name: Rails.configuration.x.aws['s3_bucket_name'])

    path = self.scenario.statistic.data_path_instance(self.name)

    log "AWS: saving bash history from Instance '#{self.name}'"
    File.open(self.scenario.statistic.data_instance_bash_histories_path(self.name), "wb") do |f|
      f.write(aws_S3_object_get_and_read(bucket, aws_S3_object_name('bash_history')) )
    end

    log "AWS: saving exit status from Instance '#{self.name}'"
    File.open(self.scenario.statistic.data_instance_exit_statuses_path(self.name), "wb") do |f|
      f.write(aws_S3_object_get_and_read(bucket, aws_S3_object_name('exit_status')) )
    end

    log "AWS: saving script log from Instance '#{self.name}'"
    File.open(self.scenario.statistic.data_instance_script_logs_path(self.name), "wb") do |f|
      f.write(aws_S3_object_get_and_read(bucket, aws_S3_object_name('script_log')) )
    end
  end

  def aws_instance_S3_files_save_no_log
    time = Time.now.strftime("%y_%m_%d")
    bucket = aws_call('aws_S3_bucket_get', name: Rails.configuration.x.aws['s3_bucket_name'])

    path = self.scenario.statistic.data_path_instance(self.name)

    File.open(self.scenario.statistic.data_instance_bash_histories_path(self.name), "wb") do |f|
      f.write(aws_S3_object_get_and_read_no_log(bucket, aws_S3_object_name('bash_history')) )
    end

    File.open(self.scenario.statistic.data_instance_exit_statuses_path(self.name), "wb") do |f|
      f.write(aws_S3_object_get_and_read_no_log(bucket, aws_S3_object_name('exit_status')) )
    end

    File.open(self.scenario.statistic.data_instance_script_logs_path(self.name), "wb") do |f|
      f.write(aws_S3_object_get_and_read_no_log(bucket, aws_S3_object_name('script_log')) )
    end
  end

  def aws_instance_S3_files_create
    bucket = aws_call('aws_S3_bucket_get', name: Rails.configuration.x.aws['s3_bucket_name'])
    if not aws_call('aws_obj_exists?', obj: bucket)
      log "AWS: creating S3 Bucket '#{Rails.configuration.x.aws['s3_bucket_name']}'"
      bucekt = aws_call('aws_S3_bucket_create', name: Rails.configuration.x.aws['s3_bucket_name'])
    end

    aws_instance_S3_object_create(bucket, 'exit_status', :exit_status_page, :write)
    aws_instance_S3_object_create(bucket, 'script_log', :script_log_page, :write)
    aws_instance_S3_object_create(bucket, 'bash_history', :bash_history_page, :write)

    obj = aws_instance_S3_object_create(bucket, 'com', :com_page, :write)
    log "AWS: writing to S3Object '#{obj.key}'"
    aws_call('aws_S3_object_write', obj: obj, data: 'waiting')

    obj = aws_instance_S3_object_create(bucket, 'cookbook', :cookbook_url, :read)
    log "AWS: writing to S3Object '#{obj.key}'"
    aws_call('aws_S3_object_write', obj: obj, data: self.generate_cookbook)
  end

  def aws_instance_S3_object_create(bucket, name, attribute, url_method)
    name = aws_S3_object_name(name)
    log "AWS: creating S3 Object '#{name}'"
    obj = aws_call('aws_S3_obj_create', bucket: bucket, name: name)
    
    log "AWS: getting S3Object url for '#{obj.key}'"
    url = aws_call('aws_S3_bucket_url_get', obj: obj, method: url_method)
    self.update_attribute(attribute, url.to_s)

    obj
  end

  def aws_S3_bucket_url_get(opts)
    if opts[:method] == :write
      opts[:obj].url_for(opts[:method], expires: 30.days, content_type: 'text/plain')
    else
      opts[:obj].url_for(opts[:method], expires: 30.days)
    end
  end

  def aws_instance_S3_files_delete
    log "AWS: looking for instance S3 files to delete"
    bucket = aws_call('aws_S3_bucket_get', name: Rails.configuration.x.aws['s3_bucket_name'])
    return false if not aws_call('aws_obj_exists?', obj: bucket)

    ret = true if aws_instance_S3_object_delete(bucket, aws_S3_object_name('cookbook'), :cookbook_url)
    ret = true if aws_instance_S3_object_delete(bucket, aws_S3_object_name('com'), :com_page)
    ret = true if aws_instance_S3_object_delete(bucket, aws_S3_object_name('bash_history'), :bash_history_page)
    ret = true if aws_instance_S3_object_delete(bucket, aws_S3_object_name('exit_status'), :exit_status_page)
    ret = true if aws_instance_S3_object_delete(bucket, aws_S3_object_name('script_log'), :script_log_page)
    ret
  end

  def aws_instance_S3_object_delete(bucket, name, attribute)
    obj = aws_call('aws_S3_obj_get', bucket: bucket, name: name)
    if aws_call('aws_obj_exists?', obj: obj)
      log "AWS: deleting S3Object '#{obj.key}'"
      aws_call('aws_obj_delete', obj: obj)
    else
      return false
    end
    self.update_attribute(attribute, "")
    true
  end

  def aws_S3_object_name(suffix)
    "#{Rails.configuration.x.aws['iam_user_name']}_#{self.scenario.user.name}_#{self.scenario.name}_#{self.scenario.id.to_s}_#{self.name}_#{self.id.to_s}_#{self.uuid[0..5]}_#{suffix}"
  end

  def aws_S3_object_get_and_read(bucket, name)
    log "AWS: getting S3Object 'name'"
    object = aws_call('aws_S3_object_get', bucket: bucket, name: name)
    if aws_call('aws_obj_exists?', obj: object)
      log "AWS: reading S3Object '#{object.key}'"
      return aws_call('aws_S3_object_read', object: object)
    end
    return ""
  rescue AWS::S3::Errors::NoSuchKey => e
    return ""
  end

  def aws_S3_object_get_and_read_no_log(bucket, name)
    object = aws_call('aws_S3_object_get', bucket: bucket, name: name)
    if aws_call('aws_obj_exists?', obj: object)
      return aws_call('aws_S3_object_read', object: object)
    end
    return ""
  rescue AWS::S3::Errors::NoSuchKey => e
    return ""
  end


  # Helper Functions

  def aws_call(func_name, opts = {})
    return self.send(func_name, opts)
  rescue => e
    log "AWS: Call Rescue: #{e.class} opts=#{opts}"
    if e.class == AWS::EC2::Errors::RequestLimitExceeded
      log "AWS: '#{e.class}' sleeping 1s and retrying"
      sleep 1
      timeout -= 1
      retry if timeout != 0
    elsif opts.has_key?(:errs) and opts[:errs].include?(e.class)
      log "AWS: '#{e.class}' sleeping 1s and retrying at least #{opts[:errs][e.class]} more times"
      sleep 1
      opts[:errs][e.class] -= 1
      retry if opts[:errs][e.class] != 0
    end
    raise e
  end

  def aws_obj_wait_till_available(obj)
    log "AWS: waiting for #{obj.class.to_s.split("::").last} '#{obj.id}' status to change to ':available'"
    begin
      Timeout.timeout(120) do 
        sleep 1 while aws_call(
          'aws_obj_state', 
          obj: obj, 
          errs: { 
            AWS::EC2::Errors::InvalidVpcID::NotFound => 60,
            AWS::EC2::Errors::InvalidSubnetID::NotFound => 60
          } 
        ) != :available
      end
    rescue Timeout::Error => e
      raise "AWS: timeout while waiting for #{obj.class.to_s.split("::").last} '#{obj.id} status to change to ':available'"
    end
  end

  def aws_obj_tags_default(obj)
    log "AWS: creating default tags for #{obj.class.to_s.split("::").last} '#{obj.id}'"
    aws_call('aws_obj_tag', obj: obj, tag: "Name", value: "#{Rails.configuration.x.aws['iam_user_name']}-#{self.scenario.user.name}-#{self.scenario.name}-#{self.scenario.id.to_s}")
    aws_call('aws_obj_tag', obj: obj, tag: 'host', value: Rails.configuration.x.aws['iam_user_name'])
    aws_call('aws_obj_tag', obj: obj, tag: 'instructor', value: self.scenario.user.name)
    aws_call('aws_obj_tag', obj: obj, tag: 'scenario_id', value: self.scenario.id)
  end

  # AWS

  def aws_obj_delete(opts)
    opts[:obj].delete
  end

  def aws_obj_exists?(opts)
    opts[:obj].exists?
  end

  def aws_obj_state(opts)
    opts[:obj].state
  end

  def aws_obj_tag(opts)
    opts[:obj].tag(opts[:tag], value: opts[:value])
  end

  # AWS::VPC
  def aws_vpc_create(opts)
    AWS::EC2.new.vpcs.create(self.cidr_block)
  end

  def aws_vpc_get(opts)
    AWS::EC2.new.vpcs[opts[:vpc_id]]
  end

  def aws_vpc_internet_gateway_get(opts)
    opts[:vpc].internet_gateway
  end

  def aws_vcp_network_acls_get(opts)
    opts[:vpc].network_acls.select{ |acl| !acl.default}
  end

  def aws_vpc_route_table_create(opts)
    AWS::EC2::RouteTableCollection.new.create(vpc_id: self.cloud.driver_id)
  end

  def aws_vpc_route_tables_get(opts)
    opts[:vpc].route_tables.select{ |rt| !rt.main? }
  end

  def aws_vpc_security_group_get(opts)
    opts[:vpc].security_groups.first
  end

  def aws_vpc_security_groups_get(opts)
    opts[:vpc].security_groups.select{ |sg| !sg.name == "default"}
  end

  # AWS::Subnet
  def aws_subnet_create(opts)
    AWS::EC2::SubnetCollection.new.create(opts[:cidr_block], vpc_id: opts[:vpc_id])
  end

  def aws_subnet_get(opts)
    AWS::EC2.new.subnets[opts[:subnet_id]]
  end

  def aws_subnet_route_table_route_to_nat_create(opts)
    AWS::EC2.new.subnets[opts[:subnet_id]].route_table.create_route("0.0.0.0/0", { instance: opts[:instance_id] } )
  end

  def aws_subnet_route_table_association_get(opts)
    opts[:subnet].route_table_association
  end

  # AWS::Instance

  def aws_instance_block_devices_get(opts)
    opts[:instance].block_devices
  end

  def aws_instance_block_device_ebs_delete_on_termination_set(opts)
    AWS::EC2.new.client.modify_instance_attribute(
      instance_id: opts[:instance].id,
      attribute: "blockDeviceMapping",
      block_device_mappings: [device_name: opts[:block_device][:device_name], ebs:{ delete_on_termination: true}]
    )
  end

  def aws_instance_create(opts)
    AWS::EC2::InstanceCollection.new.create(
      image_id: Rails.configuration.x.aws[Rails.configuration.x.aws['region']]["ami_#{self.os}"], 
      private_ip_address: self.ip_address,
      key_name: Rails.configuration.x.aws['ec2_key_pair_name'],
      user_data: self.generate_init,
      instance_type: "t2.small",
      subnet: self.subnet.driver_id
    )
  end

  def aws_instance_elastic_ip_disassociate(opts)
    opts[:instance].disassociate_elastic_ip
  end

  def aws_instance_elastic_ip_get(opts)
    opts[:instance].elastic_ip
  end

  def aws_instance_elastic_ip_associate(opts)
    opts[:instance].associate_elastic_ip(opts[:elastic_ip])
  end

  def aws_instance_get(opts)
    AWS::EC2.new.instances[opts[:instance_id]]
  end

  def aws_instance_network_interface_first_source_dest_check_disable(opts)
    opts[:instance].network_interfaces.first.source_dest_check = false
  end

  def aws_instance_status(opts)
    opts[:instance].status
  end

  # AWS::S3

  def aws_S3_object_get(opts)
    opts[:bucket].objects[opts[:name]]
  end

  def aws_S3_object_read(opts)
    opts[:object].read
  end

  def aws_S3_object_write(opts)
    opts[:obj].write(opts[:data])
  end

  def aws_S3_obj_url_get(opts)
    opts[:obj].url_for(opts[:method], opts[:url_opts]).to_s
  end

  def aws_S3_obj_write(opts)
  end

  def aws_S3_bucket_get(opts)
    AWS::S3.new.buckets[opts[:name]]
  end

  def aws_S3_bucket_create(opts)
    AWS::S3.new.buckets.create(opts[:name])
  end

  def aws_S3_obj_create(opts)
    opts[:bucket].objects.create(opts[:name], "")
  end

  def aws_S3_obj_get(opts)
    opts[:bucket].objects[opts[:name]]
  end

  # AWS::ElasticIP

  def aws_elastic_ip_create(opts)
    AWS::EC2::ElasticIpCollection.new.create(vpc: true)
  end

  # AWS::RouteTable

  def aws_route_table_association_main?(opts)
    opts[:route_table_association].main?
  end

  def aws_route_table_instance_route_create(opts)
    opts[:route_table].create_route("0.0.0.0/0", { instance: opts[:instance_id]  } )
  end

  def aws_route_table_internet_gateway_route_create(opts)
    opts[:route_table].create_route("0.0.0.0/0", { internet_gateway: opts[:internet_gateway] } )
  end

  def aws_route_table_subnet_assign(opts)
    opts[:subnet].route_table = opts[:route_table]
  end

  # AWS::InternetGateway

  def aws_internet_gateway_create(opts)
    opts[:vpc].internet_gateway = AWS::EC2.new.internet_gateways.create
  end

  def aws_internet_gateway_vpc_detach(opts)
    opts[:internet_gateway].detach(opts[:vpc])
  end

  # AWS::SecurityGroup

  def aws_security_group_disable_outbound(opts)
    opts[:security_group].revoke_egress('0.0.0.0/0')
  end

  def aws_security_group_enable_inbound(opts)
    opts[:security_group].authorize_ingress(:tcp, 20..8080)
  end

  def aws_security_group_enable_outbound_port_443(opts)
    opts[:security_group].authorize_egress('0.0.0.0/0', protocol: :tcp, ports: 443)
  end

  def aws_security_group_enable_outbound_port_80(opts)
    opts[:security_group].authorize_egress('0.0.0.0/0', protocol: :tcp, ports: 80)
  end

  def aws_security_group_enable_outbound_to_subnets(opts)
    opts[:security_group].authorize_egress('10.0.0.0/16')
  end

end
