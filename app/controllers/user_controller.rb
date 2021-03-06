class UserController < ApplicationController
  include AllowDelegateViewAs
  include AllowLti

  def am_i_logged_in
    response.headers['Cache-Control'] = 'no-cache, no-store, private, must-revalidate'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = '-1'
    render :json => {
      :amILoggedIn => !!session['user_id']
    }.to_json
  end

  def my_status
    ActiveRecordHelper.clear_stale_connections
    status = {}
    features = HashConverter.camelize Settings.features.marshal_dump
    user_id = session['user_id']

    if user_id
      #TODO: Either User::Visit model should be removed (if no longer needed), or User::Visit.record should be moved
      # out into its own endpoint. The my_status endpoint is a GET, not a POST or PUT - it shouldn't be writing data
      User::Visit.record user_id if current_user.directly_authenticated?

      status.merge! User::Api.from_session(session).get_feed
      status.merge!({
        :academicRoles => MyAcademics::MyAcademicRoles.from_session(session).get_feed
      })
    end

    status.merge!({
      :isBasicAuthEnabled => Settings.developer_auth.enabled,
      :isLoggedIn => !!user_id,
      :features => features,
      :youtubeSplashId => Settings.youtube_splash_id
    })
    render :json => status.to_json
  end

  def record_first_login
    User::Api.from_session(session).record_first_login if current_user.directly_authenticated?
    render :nothing => true, :status => 204
  end

end
