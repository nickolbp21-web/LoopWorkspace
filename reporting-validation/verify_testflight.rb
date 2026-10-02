require 'spaceship'
require 'json'
require 'time'

# Read-only verification of the explicitly approved reporting candidate.
Spaceship::ConnectAPI.token = Spaceship::ConnectAPI::Token.create(
  key_id: ENV.fetch('FASTLANE_KEY_ID'),
  issuer_id: ENV.fetch('FASTLANE_ISSUER_ID'),
  key: ENV.fetch('FASTLANE_KEY'), duration: 1200
)
app = Spaceship::ConnectAPI::App.find("com.#{ENV.fetch('TEAMID')}.loopkit.Loop")
raise 'Existing app not found' unless app
previous = nil
40.times do
  builds = Spaceship::ConnectAPI::Build.all(app_id: app.id, version: '3.14.8', build_number: '3')
  build = builds.find { |b| Time.parse(b.uploaded_date) >= Time.parse('2026-10-02T03:36:00Z') }
  status = build ? {version: build.app_version, build: build.version,
    processing: build.processing_state, ready_for_internal_testing: build.ready_for_internal_testing?,
    expired: build.expired} : {processing: 'AWAITING_APPROVED_UPLOAD'}
  if status != previous
    puts JSON.generate(status)
    previous = status
  end
  if build
    abort 'Apple rejected candidate processing' if ['FAILED', 'INVALID'].include?(build.processing_state)
    exit 0 if build.processing_state == 'VALID' && build.ready_for_internal_testing? && !build.expired
  end
  sleep 30
end
abort 'Candidate processing not ready within verification window'
