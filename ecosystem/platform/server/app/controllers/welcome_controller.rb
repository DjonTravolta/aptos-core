# frozen_string_literal: true

# Copyright (c) Aptos
# SPDX-License-Identifier: Apache-2.0

class WelcomeController < ApplicationController
  layout 'it1'

  before_action :ensure_confirmed!, only: %i[it1]

  def index
    @login_dialog = DialogComponent.new
  end

  def it1
    redirect_to root_path unless user_signed_in?
    @it1_registration_closed = Flipper.enabled?(:it1_registration_closed, current_user)
    @steps = [
      connect_discord_step,
      node_registration_step,
      identity_verification_step
    ].map do |h|
      # rubocop:disable Style/OpenStructUse
      OpenStruct.new(**h)
      # rubocop:enable Style/OpenStructUse
    end
    first_incomplete = @steps.index { |step| !step.completed }
    @steps[first_incomplete + 1..].each { |step| step.disabled = true } if first_incomplete
    @steps.each { |step| step.disabled = true } if @it1_registration_closed
  end

  private

  def connect_discord_step
    completed = current_user.authorizations.where(provider: :discord).exists?
    {
      name: :connect_discord,
      completed:,
      dialog: completed ? nil : DialogComponent.new
    }
  end

  def node_registration_step
    completed = !!current_user.it1_profile&.validator_verified?
    {
      name: :node_registration,
      completed:,
      disabled: Flipper.enabled?(:it1_node_registration_disabled, current_user),
      href: completed ? edit_it1_profile_path(current_user.it1_profile) : new_it1_profile_path
    }
  end

  def identity_verification_step
    completed = current_user.kyc_complete?
    {
      name: :identity_verification,
      completed:,
      href: completed ? nil : onboarding_kyc_redirect_path
    }
  end
end
