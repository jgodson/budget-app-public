class MetricsController < ApplicationController
  def index
    require 'prometheus/client/formats/text'
    render plain: ::Prometheus::Client::Formats::Text.marshal(::Prometheus::Client.registry), content_type: 'text/plain'
  end
end
