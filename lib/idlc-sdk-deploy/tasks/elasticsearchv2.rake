namespace :elasticsearchv2 do
  task :deps do
    if ENV.include? 'ES_ENDPOINT'
      ES_ENDPOINT = ENV['ES_ENDPOINT']
    else
      ES_ENDPOINT = Idlc::Deploy::Config.get_deployment_output('es_endpoint')
    end

    ES = Idlc::Deploy::ElasticsearchV2.new(
      {
        access_key_id: ENV['AWS_ACCESS_KEY_ID'],
        secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
      },
      ENV['AWS_REGION'],
      ES_ENDPOINT
    )
  end

  desc 'Initialize ElasticSearch'
  task init: [:deps] do
    ES.create_index(ENV['APP_RELEASE'], 'dev-publish', 'axp')
  end

  desc 'Clear ElasticSearch'
  task clear: [:setup, :deps] do
    ES.delete_index('axiompro')
    ES.cleanup
  end

  desc 'Update ElasticSearch'
  task update: [:deps, :init] do
    ES.run_migrations(ENV['APP_RELEASE'], 'dev-publish', 'axp')
    ES.cleanup
  end
end
