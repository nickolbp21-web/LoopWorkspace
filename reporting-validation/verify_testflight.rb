require 'spaceship'
require 'json'
require 'time'
$stdout.sync = true

# Read-only verification of the explicitly approved reporting candidate.
Spaceship::ConnectAPI.token = Spaceship::ConnectAPI::Token.create(
  key_id: ENV.fetch('FASTLANE_KEY_ID'),
  issuer_id: ENV.fetch('FASTLANE_ISSUER_ID'),
  key: ENV.fetch('FASTLANE_KEY'), duration: 1200
)
app = Spaceship::ConnectAPI::App.find("com.#{ENV.fetch('TEAMID')}.loopkit.Loop")
raise 'Existing app not found' unless app
previous = nil
30.times do
  builds = Spaceship::ConnectAPI::Build.all(app_id: app.id, limit: 5)
  build = builds.find { |b| b.version == ENV.fetch('REPORTING_EXPECTED_BUILD') && Time.parse(b.uploaded_date) >= Time.parse(ENV.fetch('REPORTING_UPLOADED_AFTER')) }
  status = build ? {version: build.app_version, build: build.version,
    processing: build.processing_state, internal_state: build.build_beta_detail&.internal_build_state,
    external_state: build.build_beta_detail&.external_build_state, ready_for_internal_testing: build.ready_for_internal_testing?,
    expired: build.expired} : {processing: 'AWAITING_APPROVED_UPLOAD'}
  if status != previous
    puts JSON.generate(status)
    previous = status
  end
  if build
    abort 'Apple rejected candidate processing' if ['FAILED', 'INVALID'].include?(build.processing_state)
    exit 0 if build.processing_state == 'VALID' && ['READY_FOR_BETA_TESTING','IN_BETA_TESTING'].include?(build.build_beta_detail&.internal_build_state) && !build.expired
  end
  sleep 30
end
abort 'Candidate processing not ready within verification window'
