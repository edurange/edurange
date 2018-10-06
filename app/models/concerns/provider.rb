# This file is included in {Scenario}, {Cloud}, {Subnet} and {Instance}. Essentialy it has glue code for
# both defining methods dynamically (within concerns such as Aws that handle provider specific API calls) as well as
# routing those methods (within {#method_missing})
# Apart from defining these methods, the only other role this file has is to declare the "status" column, an integer corresponding to
# three states stored in the local database. They can be :stopped, :booting, or :booted. All files which include {Provider} receive this,
# and helper methods to retrieve the database state. Check out enum in Rails.
# When reading through this file (and other Concerns), think of the file including them as their "self". When a {Cloud} includes this file,
# any of these methods "self" will refer to that {Cloud cloud}.
module Provider
  extend ActiveSupport::Concern

  # Marked for removal. Including a specific provider instance in this mixin defeats the entire purpose of the provider class.
  include ProviderAws

  included do
    enum status: [
      :stopped,
      :boot_scheduled,
      :booting,
      :boot_fail,
      :booted,
      :booted_partial,
      :pausing,
      :paused,
      :pause_error,
      :starting,
      :start_error,
      :unboot_scheduled,
      :unbooting,
      :unboot_fail,
    ]
  end

  #############################################################
  # Logging

  def log(message)
    (puts "#{self.name}: #{message}"; STDOUT.flush) if @opts[:console_print]
    File.open("#{log_file}", "a+") { |f| f.write("#{self.name}: #{message}\n") }
  end

  def log_file
    "#{self.scenario.statistic.data_path_boot}/#{@opts[:boot_code]}"
  end

  def log_file_read
    File.open("#{log_file}", "r") { |f| puts f.read() }
  end

  def log_last
    if path = Dir.glob("#{self.scenario.statistic.data_path_boot}/*").max_by { |f| File.mtime(f) }
      return File.open(path, 'r').read()
    end
  end

  def clear_log
    self.update_attribute(:log, '')
  end

  #############################################################
  #  Booting

  def boot(opts = {})
    opts[:action] = :boot
    self.scenario.boot_scenario(opts) if boot_opts(opts)
  end

  def unboot(opts = {})
    opts[:action] = :unboot
    self.scenario.boot_scenario(opts) if boot_opts(opts)
  end

  def boot_opts(opts)
    opts[:console_print] = true if not opts.has_key?(:console_print)
    opts[:pretend] ||= false
    opts[:background] ||= false
    opts[:boot_code] = "#{Time.now.strftime("%y-%m-%d-%H-%M-%S")}_#{`uuidgen`[0..7]}"
    opts[:resources] ||= {}
    errs = []

    if not (opts[:resources].class == Hash)
      errs << "option ':resources' '#{resource.name}' must be Hash"
    end
    if not (opts[:console_print].class == TrueClass or opts[:console_print].class == FalseClass)
      errs << "option ':console_print' must be True or False" 
    end

    (self.class == Scenario ? self.descendents : [self]).each do |resource|
      if self.class != Scenario or (opts[:action] == :boot ? (resource.stopped?) : (resource.booted?))
        opts[:resources][resource.name] ||= {}
        opts_r = opts[:resources][resource.name]
        opts_r[:action] ||= opts[:action]
        opts_r[:pretend] ||= opts[:pretend]
        opts_r[:background] ||= opts[:background]
        opts_r[:wait] ||= opts[:wait] ? opts[:wait] : 0

        if not (opts_r.class == Hash)
          errs << "option ':resources' '#{resource.name}' must be Hash"
        end
        if not (opts_r[:pretend].class == TrueClass or opts_r[:pretend].class == FalseClass)
          errs << "option ':pretend' must be True or False"
        end
        if not (opts_r[:background].class == TrueClass or opts_r[:background].class == FalseClass)
          errs << "option ':background' must be True or False" 
        end

        if not (opts_r[:action] == :boot or opts_r[:action] == :unboot)
          errs << "option ':action' must be :boot or :unboot"
        end
      end
    end

    # check for non existent resources
    nonexistents = opts[:resources].select { |name, v| !self.scenario.resource(name) }
    if nonexistents.any?
      errs << 'Scenario resources do not exist #{nonexistents.map{ |n, k| n }}'
    end

    # check if nothing is set to boot or unboot
    if opts[:resources].size == 0
      errs << 'nothing scheduled to boot.'
    end

    # return false on errors
    if errs.any?
      errors.add(:boot, errs)
      return false
    end
    true
  end

  def boot_fail_print(e)
    log "FAIL: #{e.class} #{e.message.to_s}\n" +
      "#{self.name}: TRACE\n#{e.backtrace.select { |l| l unless /gems/ =~ l or /rvm/ =~ l }.join("\n#{self.name}:")}\n" +
      "#{self.name}: ECART"
  end

  #############################################################
  # Scenario methods

  def boot_scenario(opts)
    # set opts
    boot_scenario_set_opts(opts)

    # check for correct opts and that everything can boot
    boot_opts_validate

    # schedule descendents
    boot_scenario_schedule_descendents

    # boot descendents first up then down
    boot_scenario_descendents(descendents_boot_scheduled_descending)
    boot_scenario_descendents(descendents_unboot_scheduled_ascending)

    # wait for descendents to finish and release them
    return boot_scenario_descendents_wait_and_release
  rescue => e
    boot_fail_print(e)

    # release descendents that never started booting
    boot_scenario_boot_scheduled_release

    # wait for descendents to finish and release them
    boot_scenario_descendents_wait_and_release

    false
  end

  def boot_scenario_boot_scheduled_release
    descendents_boot_scheduled.each do |descendent|
      log "unscheduling '#{descendent.name}'"
      action = @opts[:resources][descendent.name][:action]
      result = descendent.class.where(
        "id = ? AND status = ?",
        descendent.id,
        descendent.class.statuses[:boot_scheduled]
      ).update_all(
        status:  action == :boot ? descendent.class.statuses[:stopped] : descendent.class.statuses[:booted], 
        boot_code: ""
      )
      if result > 0
        @opts[:resources].delete(descendent.name)
      end
    end
  end

  def boot_scenario_set_opts(opts)
    @opts = opts
    log "BEGIN: status=#{self.resources_status_hash} time=#{Time.now.to_i}"
  end

  # this fuctionality moved to boot_opts
  def boot_opts_validate
    log "validating options: opts=#{@opts}"

    err = []
    # check for no opts
    raise "opts must not be emtpy" if @opts.empty?
    @opts[:background] = false if not @opts.has_key?(:background)
    @opts[:console_print] = false if not @opts.has_key?(:console_print)
    @opts[:single] = false if not @opts.has_key?(:single)

    # check for non valid resource
    @opts[:resources].each do |k, v|
      err << "invalid resource in opts '#{k}'" if not self.resource(k)
      err << "must specifiy background true or false in opts" if not @opts[:resources][k].has_key?(:background)
      err << "must specifiy pretend true or false in opts" if not @opts[:resources][k].has_key?(:pretend)
    end
    raise err.to_s if err.any?

    # get relations and statuses
    relations = self.descendents_relations

    # set relations to what they would be after boot
    @opts[:resources].each do |k, v|
      next if k == :console_print or k == :boot_id
      if @opts[:resources][k][:action] == :boot
        # resources must be stooped to boot
        if relations[k][:status] != "stopped"
          err << "resource #{k} must be stopped to boot."
        else
          relations[k][:status] = "booted"
        end
      elsif @opts[:resources][k][:action] == :unboot
        if relations[k][:status] != "booted"
          err << "resource #{k} must be booted to stop."
        else
          relations[k][:status] = "stopped"
        end
      end
    end

    # check that post-boot relations are valid
    relations.each do |k, v|
      if relations[k][:parent_class] != "Scenario"
        if relations[k][:status] == "booted" and (relations[relations[k][:parent]][:status] != "booted")
          err << "resource #{k} parent must be booted, booting or scheduled to boot #{relations}"
        end

        if relations[k][:status] == "stopped" and relations[k][:children].select { |c| relations[c][:status] == "booted" }.any?
          err << "resource #{k} chidren must be stopped, unbooting or scheduled to unboot"
        end
      end
    end

    @opts[:timeout] = 60*10

    # get objects
    @opts[:resources].each do |resource_name, values|
      values[:obj] = self.scenario.resource(resource_name)
    end

    raise err.to_s if err.any?
  end

  def boot_scenario_schedule_descendents
    # schedule descendents, fail if some other boot process schedules them first
    @opts[:resources].each do |name, values|
      if values[:action] == :boot
        result = values[:obj].class.where("id = ? AND status = ?", 
          values[:obj].id, 
          values[:obj].class.statuses[:stopped]
        ).update_all(status: values[:obj].class.statuses[:boot_scheduled], boot_code: @opts[:boot_code]) > 0
      elsif values[:action] ==:unboot
        result = values[:obj].class.where("id = ? AND status = ?", 
          values[:obj].id, 
          values[:obj].class.statuses[:booted]
        ).update_all(status: values[:obj].class.statuses[:unboot_scheduled], boot_code: @opts[:boot_code]) > 0
      end

      if not result
        log "could not schedule #{name}"
        raise 'could not schedule all dependents.'
      end
    end

    log "scheduled #{@opts[:resources].keys}"
  end

  def boot_scenario_descendents(descendents)
    descendents.each do |descendent|
      opts_descendent = @opts[:resources][descendent.name]
      log "#{opts_descendent[:action]} \"#{descendent.name}\": background=#{opts_descendent[:background]}"
      if opts_descendent[:background]
        descendent.delay(queue: descendent.class.to_s.downcase).boot_descendent(@opts)
      else
        descendent.boot_descendent(@opts)
      end
    end
  end

  def boot_scenario_descendents_wait_and_release
    result = true
    @opts[:resources].each do |name, values|
      log "waiting for descendent \"#{name}\" to finish: status=#{values[:obj].status}"
      
      begin
        (sleep 1; values[:obj].reload) until values[:obj].boot_done?
      rescue ActiveRecord::RecordNotFound => e
        # skip if resource gets deleted
        next
      end
          
      # cleanup failed resources
      if values[:obj].boot_fail? or values[:obj].unboot_fail?
        log "descendent \"#{name}\" #{values[:action]} failed"
        self.errors.add(:boot, "#{self.name} descendent \"#{name}\" boot failed #{values[:obj].status}")
        values[:obj].boot_fail? ? values[:obj].set_stopped : values[:obj].set_booted
        result = false
      end

      # release resource
      values[:obj].update_attribute(:boot_code, "")
    end
    log "#{result ? 'SUCCESS' : 'FAIL'}: status=#{self.resources_status_hash}"
    return result
  end

  #############################################################
  # Descendent methods

  def boot_descendent(opts)
    # set opts
    boot_descendent_set_opts(opts)

    # try and enter boot
    boot_descendent_lock

    # check if bootable
    boot_descendent_check_bootable_unbootable

    # wait(debug purposes)
    boot_descendent_debug_wait if @opts_self.has_key?(:wait)

    # wait for parent or children
    if @opts_self[:action] == :boot
      boot_descendent_wait_for_parent if self.class != Cloud
    else
      boot_descendent_wait_for_children if self.class != Instance
    end

    # do class specific booting tasks
    boot_descendent_main

    # success
    boot_descendent_success
  rescue => e
    boot_descendent_failure(e)
  end

  def boot_descendent_set_opts(opts)
    @opts = opts
    @opts_self = @opts[:resources][self.name]
    @opts_self[:obj].reload
    log "BEGIN: opts=#{@opts_self} time=#{Time.now.to_i}"
  end

  def boot_descendent_lock
    log "getting boot lock"
    if self.class.where(
        "id = ? AND (status = ? OR status = ?) AND boot_code = ?", 
        self.id, 
        @opts_self[:action] == :boot ? self.class.statuses[:stopped] : self.class.statuses[:booted], 
        @opts_self[:action] == :boot ? self.class.statuses[:boot_scheduled] : self.class.statuses[:unboot_scheduled], 
        @opts[:boot_code]
      ).update_all(status: @opts_self[:action] == :boot ? self.class.statuses[:booting] : self.class.statuses[:unbooting]) <= 0
      self.reload
      raise "#{self.name} status:#{self.status} boot_code: '#{self.boot_code}' must be #{@opts_self[:action] == :boot ? 'stopped to boot' : 'booted to unboot'}, have boot code: '#{self.boot_code}' and be the only process currently booting this resource"
    end
  end

  def boot_descendent_check_bootable_unbootable
    if @opts_self[:action] == :boot
      raise "parent \"#{self.parent.name}\" status:\"#{self.parent.status}\" needs to be booted or booting" if not self.bootable?
    elsif @opts_self[:action] == :unboot
      raise "parent \"#{self.parent.name}\" status:\"#{self.parent.status}\" needs to be booted or booting" if not self.unbootable?
    end
  end

  def boot_descendent_debug_wait
    log "debug waiting #{@opts_self[:wait]}s" if @opts_self[:wait] != 0
    sleep @opts_self[:wait]
  end

  def boot_descendent_wait_for_parent
    log "wait for parent to finish booting"
    boot_descendent_wait_till_boot_done(self.parent)
  end

  def boot_descendent_wait_for_children
    log "wait for children to unboot"
    self.children.each { |child| boot_descendent_wait_till_boot_done(child) }
  end

  def boot_descendent_wait_till_boot_done(descendent)
    name = descendent.name
    log "waiting up to #{@opts[:timeout]}s for '#{descendent.name}' to finish booting"
    begin
      Timeout.timeout(@opts[:timeout]) do
        while not descendent.boot_done?
          sleep 1
          descendent.reload
        end
      end
    rescue ActiveRecord::RecordNotFound => e
      raise "descendent '#{name}' no longer exists"
    end
  rescue Timeout::Error => e
    raise "timeout waiting for '#{name}' to finish booting"
  end

  def boot_descendent_main
    if @opts_self[:pretend]
      raise 'test error failed on purpose' if @opts_self[:fail]
    else
      self.send("#{Rails.configuration.x.provider}_#{self.class.to_s.downcase}_#{@opts_self[:action].to_s}")
    end
  end

  def boot_descendent_success
    @opts_self[:action] == :boot ? self.set_booted : self.set_stopped
    log "SUCCESS: status=#{self.status} time=#{Time.now.to_i}"
    self.update_attribute(:boot_code, "")
  end

  def boot_descendent_failure(e)
    boot_fail_print(e)
    if @opts_self[:action] == :boot
      self.set_boot_fail
      log "Cleaning up '#{self.name}'"
      self.send("#{Rails.configuration.x.provider}_#{self.class.to_s.downcase}_unboot")
    else
      self.set_unboot_fail
    end
  end

  def pause
    if not (self.class == Instance or self.class == Scenario)
      return
    end

    if not self.booted?
      errors.add(:boot, "must be booted to pause")
      return
    end
    
    if self.class == Scenario
      self.set_pausing
      self.delay(queue: self.class.to_s.downcase).send("provider_pause_#{self.class.to_s.downcase}")
    else
      self.send("provider_pause_#{self.class.to_s.downcase}")
    end
  end

  def start
    if not (self.class == Instance or self.class == Scenario)
      return
    end

    if not self.paused?
      errors.add(:boot, "must be paused to start")
      return
    end

    if self.class == Scenario
      self.set_starting
      self.delay(queue: self.class.to_s.downcase).send("provider_start_#{self.class.to_s.downcase}")
    else
      self.send("provider_start_#{self.class.to_s.downcase}")
    end
  end

  #############################################################
  # Relations 

  def family
    self.ancestors + [self] + self.descendents
  end

  def children
    arr = []
    arr += self.clouds if self.class == Scenario
    arr += self.subnets if self.class == Cloud
    arr += self.instances if self.class == Subnet
    arr
  end

  def children_booting?
    self.children.select { |c| not c.boot_done? }.any?
  end

  def descendents
    arr = []
    arr += self.clouds if self.class == Scenario
    arr += self.subnets if [Scenario,Cloud].include? self.class
    arr += self.instances if [Scenario,Cloud,Subnet].include? self.class
    arr
  end

  def parent
    return nil if self.class == Scenario
    return self.scenario if self.class == Cloud
    return self.cloud if self.class == Subnet
    return self.subnet if self.class == Instance
  end

  def ancestors
    arr = []
    arr << self.scenario if [Instance,Subnet,Cloud].include? self.class
    arr << self.cloud if [Instance,Subnet].include? self.class
    arr << self.subnet if self.class == Instance
    arr
  end

  def descendents_relations
    hash = {}
    self.descendents.each do |d|
      hash[d.name] = {}
      hash[d.name][:class] = d.class.to_s
      hash[d.name][:status] = d.status
      hash[d.name][:parent] = d.parent ? d.parent.name : nil
      hash[d.name][:parent_class] = d.parent ? d.parent.class.to_s : nil
      hash[d.name][:children] = d.children.map { |d| d.name }
    end
    hash
  end

  def descendents_status_relations
    hash = {}
    self.descendents.each do |d|
      hash[d.name] = {}
      hash[d.name][:class] = d.class.to_s
      hash[d.name][:status] = d.status
      hash[d.name][:parent] = d.parent ? d.parent.name : nil
      hash[d.name][:parent_class] = d.parent ? d.parent.class.to_s : nil
      hash[d.name][:children] = d.children.map { |d| d.name }
    end
    hash
  end

  def descendents_boot_in
    self.reload
    self.descendents.select { |d| d.boot_code == self.boot_code and self.boot_code != "" }
  end

  def descendents_boot_scheduled
    self.reload
    self.descendents.select { |d| ((d.scheduled?) and (d.boot_code == @opts[:boot_code])) }
  end

  def descendents_boot_scheduled_descending
    self.reload
    d = []
    d += self.descendents.select do |d| 
        d.class == Cloud and ((d.scheduled?) and (d.boot_code == @opts[:boot_code])) and @opts[:resources][d.name][:action] == :boot
    end
    d += self.descendents.select do |d| 
      d.class == Subnet and ((d.scheduled?) and (d.boot_code == @opts[:boot_code])) and @opts[:resources][d.name][:action] == :boot
    end
    d += self.descendents.select do |d| 
      d.class == Instance and ((d.scheduled?) and (d.boot_code == @opts[:boot_code])) and @opts[:resources][d.name][:action] == :boot
    end
    d
  end

  def descendents_unboot_scheduled_ascending
    self.reload
    d = []
    d += self.descendents.select do |d| 
      d.class == Instance and ((d.scheduled?) and (d.boot_code == @opts[:boot_code])) and @opts[:resources][d.name][:action] == :unboot
    end
    d += self.descendents.select do |d| 
      d.class == Subnet and ((d.scheduled?) and (d.boot_code == @opts[:boot_code])) and @opts[:resources][d.name][:action] == :unboot
    end
    d += self.descendents.select do |d| 
      d.class == Cloud and ((d.scheduled?) and (d.boot_code == @opts[:boot_code])) and @opts[:resources][d.name][:action] == :unboot
    end
    d
  end

  def descendents_boot_scheduled_names
    self.descendents.select { |d| ((d.scheduled?) and (d.boot_code == self.boot_code)) }.map { |d| d.name }
  end

  def resource(name)
    self.descendents.each { |d| return d if d.name == name }
    nil
  end

  def resources_status_hash
    self.reload
    a = { self.name => self.status }
    self.descendents.each { |d| a = a.merge({ d.name => d.status}) }
    a
  end

  def scheduled?
    self.boot_scheduled? or self.unboot_scheduled?
  end

  def boot_done?
    self.reload
    (self.stopped? or self.boot_fail? or self.unboot_fail? or self.booted?)
  end

  def bootable?
    self.reload
    if self.class == Scenario
      return self.descendents.select { |d| d.stopped? }.any?
    end
    return false if not (self.stopped? or self.booting? or self.boot_scheduled?)
    return true if self.class == Cloud
    return (self.parent.boot_scheduled? or self.parent.booting? or self.parent.booted?)
  end

  def unbootable?
    self.reload
    if self.class == Scenario
      return self.descendents.select { |d| d.booted? }.any?
    end
    return false if not (self.booted? or self.unbooting? or self.unboot_scheduled?)
    return true if self.class == Instance
    return (not self.children.select { |c| c.booted? }.any?)
  end

  #############################################################
  #  Status set and get

  def set_stopped
    self.update_attribute(:status, :stopped)
    self.scenario.status_update if self.class != Scenario
  end

  def set_booting
    self.update_attribute(:status, :booting)
    self.scenario.status_update if self.class != Scenario
  end

  def set_boot_fail
    self.update_attribute(:status, :boot_fail)
    self.scenario.status_update if self.class != Scenario
  end

  def set_booted
    self.update_attribute(:status, :booted)
    self.scenario.status_update if self.class != Scenario
  end

  def set_paused
    self.update_attribute(:status, :paused)
    self.scenario.status_update if self.class != Scenario
  end

  def set_pausing
    self.update_attribute(:status, :pausing)
    self.scenario.status_update if self.class != Scenario
  end

  def set_starting
    self.update_attribute(:status, :starting)
    self.scenario.status_update if self.class != Scenario
  end

  def set_unbooting
    self.update_attribute(:status, :unbooting)
    self.scenario.status_update if self.class != Scenario
  end

  def set_unboot_fail
    self.update_attribute(:status, :unboot_fail)
    self.scenario.status_update if self.class != Scenario
  end

  # Dynamically calls the method provided, routing it through the provider concern specified at runtime by
  # Settings.driver.
  # @param meth The method to call
  # @param args The arguments to pass
  # @param block Any block arguments to pass
  # @see #run_provider_method
  # @return [nil]
  def method_missing(meth, *args, &block)
    if meth.to_s =~ /^provider_(.+)$/
      run_provider_method($1, *args, &block)
    else
      super
    end
  end

  # Calls the method provided in the EDURange config, defined in the concerns for each Driver at runtime.
  # Currently does not pass arguments.
  # @return [nil]
  def run_provider_method(provider_method, *args, &block)
    self.send("#{Rails.configuration.x.provider}_#{provider_method}".to_sym, *args)
  end

end
