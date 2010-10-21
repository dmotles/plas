require 'money'
require 'activemerchant'

class RegistrationsController < ApplicationController
  include ActiveMerchant::Billing
  
  before_filter :get_event

  def get_event
    @event = Event.find(params[:event_id])
    #this should be impossible, because the events controller will handle it
    if !@event
      redirect_to events_path
    end
  end

  #store the gateway objecti
  def gateway
    @gateway ||= ActiveMerchant::Billing::PaypalExpressGateway.new(
      :login => Pcfg.get('paypal.login'),
      :password => Pcfg.get('paypal.password'),
      :signature => Pcfg.get('paypal.signature')
    )
  end
  private :gateway

  # GET /register
  def register
    @tickets = @event.tickets
    respond_to do |format|
      format.html # register.html.erb
      format.xml { render :xml => @tickets }
    end
  end

  # POST /review
  def review
    @desired_tickets = params[:ticket]
    if true
      redirect_to event_register_url
    end
    @tickets = []
    @order_total = 0
    @desired_tickets.each do |k,v|
      #TODO: I'm sure this can be done more efficiently and securely
      ticket = Ticket.find(v["ticket_id"])
      @desired_tickets[k]["name"] = ticket.name
      @desired_tickets[k]["price"] = ticket.price
      @desired_tickets[k]["total"] = v["number"].to_i * ticket.price
      @order_total = @order_total +  @desired_tickets[k]["total"]
    end

    session[:tickets] = @desired_tickets
    session[:order_total] = @order_total #is this safe to put in here? doubtful

    respond_to do |format|
      format.html # review.html.erb
      #TODO: xml version should show provide ticket information and totals
      format.xml { render :xml => _("Not yet implemented") }
    end
  end

  #The paypal integration dance comes from here:
  # http://webtempest.com/paypal-express-transactions-with-ruby-on-rails/

  #redirect the user to paypal for login and confirmation there
  def paypal_redirect
    setup_response = gateway.setup_purchase(session[:order_total],
                                            :ip => request.remote_ip,
                                            :return_url => url_for(:action => 'confirm', :only_path => false),
                                            :cancel_return_url => url_for(:action => 'register', :only_path => false)
                                           )
    redirect_to gateway.redirect_url_for(setup_response.token)
  end
  
  def confirm
    customer_detauls = gateway.details_for(params[:token])
    if !details_response.success?
      @message = details_response.message
      render :action => 'error'
      return
    end
    @address = customer_details.address
  end

  #GET /pay
  def pay
    #this is where we actually charge paypal
    purchase = gateway.purchase(session[:order_total],
                                :ip => request.remote_ip,
                                :payer_id => params[:payer_id],
                                :token => params[:token]
                               )
    if purchase.success?
      respond_to do |format|
       format.html # 
       #TODO: xml version should show provide ticket information and totals
       format.xml { render :xml => _("Not yet implemented") }
      end
    else
      render :action => 'error'
    end
  end

  #GET /return
  def return
    #this is where paypal sends the user following the transaction
    if payment_successful? 
      render :action => "success"
    else
      render :action => "error"
    end
  end

  #GET /success
  def success
    #shown if the paypal transaction succeeded
    #create the registrations
    #clear the session's tickets
    session[:tickets] = nil

    respond_to do |format|
      format.html # pay.html.erb
      #TODO: xml version should show provide ticket information and totals
      format.xml { render :xml => _("Not yet implemented") }
    end
  end

  #GET /error
  def error
    #shown if the paypal transaction failed
    respond_to do |format|
      format.html # pay.html.erb
      #TODO: xml version should show provide ticket information and totals
      format.xml { render :xml => _("Not yet implemented") }
    end
  end
  
  # GET /registrations
  # GET /registrations.xml
  def index
    @registrations = Registration.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @registrations }
    end
  end

  # GET /registrations/1
  # GET /registrations/1.xml
  def show
    @registration = Registration.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @registration }
    end
  end

  # GET /registrations/new
  # GET /registrations/new.xml
  def new
    @registration = Registration.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @registration }
    end
  end

  # GET /registrations/1/edit
  def edit
    @registration = Registration.find(params[:id])
  end

  # POST /registrations
  # POST /registrations.xml
  def create
    @registration = Registration.new(params[:registration])

    respond_to do |format|
      if @registration.save
        format.html { redirect_to(@registration, :notice => 'Registration was successfully created.') }
        format.xml  { render :xml => @registration, :status => :created, :location => @registration }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @registration.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /registrations/1
  # PUT /registrations/1.xml
  def update
    @registration = Registration.find(params[:id])

    respond_to do |format|
      if @registration.update_attributes(params[:registration])
        format.html { redirect_to(@registration, :notice => 'Registration was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @registration.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /registrations/1
  # DELETE /registrations/1.xml
  def destroy
    @registration = Registration.find(params[:id])
    @registration.destroy

    respond_to do |format|
      format.html { redirect_to(registrations_url) }
      format.xml  { head :ok }
    end
  end
end
