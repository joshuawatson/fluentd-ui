class Fluentd::SettingsController < ApplicationController
  before_action :login_required
  before_action :find_fluentd

  def show
    @config = @fluentd.agent.config
  end

  def edit
    @config = @fluentd.agent.config
  end

  def  update
    @fluentd.agent.config_write params[:config]
    @fluentd.agent.restart if @fluentd.agent.running?
    redirect_to daemon_setting_path(@fluentd)
  end

  def in_tail_after_file_choose
    @setting = Fluentd::Setting::InTail.new({
      :path => params[:path],
      :tag => nil,
    })
  end

  def in_tail_after_format
    @setting = Fluentd::Setting::InTail.new(setting_params)
  end

  def in_tail_confirm
    @setting = Fluentd::Setting::InTail.new(setting_params)
    if params[:back]
      return render :in_tail_after_file_choose
    end
    unless @setting.valid?
      return render :in_tail_after_format
    end
  end

  def in_tail_finish
    @setting = Fluentd::Setting::InTail.new(setting_params)
    if params[:back]
      return render :in_tail_after_format
    end

    unless @setting.valid?
      return render "in_tail_after_format"
    end

    if @fluentd.agent.configuration.to_s.include?(@setting.to_conf.strip)
      @setting.errors.add(:base, :duplicated_conf)
      return render "in_tail_after_format"
    end

    @fluentd.agent.config_append @setting.to_conf
    @fluentd.agent.restart if @fluentd.agent.running?
    redirect_to daemon_setting_path(@fluentd)
  end

  private

  def setting_params
    setting_params = params.require(:setting).permit(:path, :format, :regexp, *Fluentd::Setting::InTail.known_formats, :tag, :rotate_wait, :pos_file, :read_from_head, :refresh_interval)
    {
      :pos_file => "/tmp/fluentd-#{@fluentd.id}-#{Time.now.to_i}.pos",
    }.merge setting_params
  end
end
