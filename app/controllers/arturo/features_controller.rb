require 'action_controller'
require 'arturo/feature_params_support'

# TODO: this doesn't do anything radically out of the ordinary.
#       Are there Rails 3 patterns/mixins/methods I can use
#       to clean it up a bit?
module Arturo

  # Handles all Feature actions. Clients of the Arturo engine
  # should redefine Arturo::FeaturesController#may_manage_features? to
  # return true only for users who are permitted to manage features.
  class FeaturesController < ApplicationController
    include Arturo::FeatureManagement
    include Arturo::FeatureParamsSupport

    unloadable
    respond_to :html, :json, :xml
    before_filter :require_permission
    before_filter :load_feature, :only => [ :show, :edit, :update, :destroy ]

    if Rails::VERSION::MAJOR == 3 && Rails::VERSION::MINOR == 0
      def arturo_engine
        self
      end
      helper_method :arturo_engine
    end

    def index
      @features = Arturo::Feature.all
      respond_with @features
    end

    def update_all
      updated_count = 0
      errors = []
      features_params.each do |id, attributes|
        feature = Arturo::Feature.find_by_id(id)
        if feature.blank?
          errors << t('arturo.features.flash.no_such_feature', :id => id)
        elsif feature.update_attributes(attributes)
          updated_count += 1
        else
          errors << t('arturo.features.flash.error_updating', :id => id, :errors => feature.errors.full_messages.to_sentence)
        end
      end
      if errors.any?
        flash[:error] = errors
      else
        flash[:success] = t('arturo.features.flash.updated_many', :count => updated_count)
      end
      redirect_to arturo_engine.features_path
    end

    def show
      respond_with @feature
    end

    def new
      @feature = Arturo::Feature.new(feature_params)
      respond_with @feature
    end

    def create
      @feature = Arturo::Feature.new(feature_params)
      if @feature.save
        notify('created')
      else
        notify('error_creating', :alert)
      end
      respond_with @feature, :location => arturo_engine.features_path
    end

    def edit
      respond_with @feature
    end

    def update
      if @feature.update_attributes(feature_params)
        notify('updated')
      else
        notify('error_updating', :alert)
      end
      respond_with @feature, :location => arturo_engine.feature_path(@feature)
    end

    def destroy
      if @feature.destroy
        notify('removed')
      else
        notify('error_removing', :alert)
      end
      respond_with @feature, :location => arturo_engine.features_path
    end

    protected

    def load_feature
      @feature ||= Arturo::Feature.find(params[:id])
    end

    def require_permission
      unless may_manage_features?
        render :action => 'forbidden', :status => 403
        return false
      end
    end

    private

    def notify(key, type = :notice)
      respond_to do |format|
        format.html {
          flash[type] = t("arturo.features.flash.#{key}", :name => @feature.to_s)
        }
      end
    end

  end
end
