class OrganizationsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_organization, except: [:index, :new, :create]
  after_action :verify_authorized, except: [:index, :show]

  def index
    @organizations = Organization.where(concealed: false)
                 .paginate(page: params[:page], per_page: 25).order(:name)
    session[:return_to] = organizations_path
  end

  def show
    params[:view] ||= 'events'
    @organization_show = OrganizationShowView.new(@organization, params)
    session[:return_to] = organization_path(@organization)
  end

  def new
    @organization = Organization.new
    authorize @organization
  end

  def edit
    authorize @organization
  end

  def create
    @organization = Organization.new(organization_params)
    authorize @organization

    if @organization.save
      redirect_to @organization
    else
      render 'new'
    end
  end

  def update
    authorize @organization

    if @organization.update(organization_params)
      redirect_to @organization
    else
      render 'edit'
    end
  end

  def destroy
    authorize @organization
    if @organization.events.present?
      flash[:danger] = 'An organization cannot be deleted so long as any events are associated with it. ' +
          'Delete the related events individually and then delete the organization.'
      redirect_to organization_path(@organization)
    else
      @organization.destroy
      flash[:success] = 'Organization deleted.'
      session[:return_to] = params[:referrer_path] if params[:referrer_path]
      redirect_to session.delete(:return_to) || organizations_path
    end
  end

  def stewards
    authorize @organization
    if params[:search].present?
      user = User.find_by(email: params[:search])
      if user
        if @organization.stewards.include?(user)
          flash[:warning] = 'That user is already a steward of this organization.'
        else
          @organization.add_stewardship(user)
        end
        params[:search] = nil
      else
        flash[:warning] = 'User was not located.'
      end
    end
    session[:return_to] = stewards_organization_path
  end

  def remove_steward
    authorize @organization
    user = User.find(params[:user_id])
    @organization.remove_stewardship(user)
    redirect_to stewards_organization_path
  end

  private

  def organization_params
    params.require(:organization).permit(:name, :description, :concealed)
  end

  def query_params
    params.permit(:name)
  end

  def set_organization
    @organization = Organization.find(params[:id])
  end

end