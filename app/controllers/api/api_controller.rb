# frozen_string_literal: true

module Api
  class ApiController < ApplicationController
    include JSONAPI::ActsAsResourceController
  end
end
