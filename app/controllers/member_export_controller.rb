# Copyright (C) 2009 Pascal Rettig.

class MemberExportController < CmsController # :nodoc: all
  layout 'manage'
  permit 'editor_members'
  
  def index
    cms_page_info([ [ 'E-marketing', url_for(:controller => 'emarketing') ], 
                    [ 'Email Targets', url_for(:controller =>'members', :refresh => 1 ) ],
                    'Member Download' ], 'e_marketing' )
    
    @export = DefaultsHashObject.new(:download => 'all')
    
    @include_options = [ [ 'Home Address','home' ], 
                         ['Billing Address', 'billing'], 
                         ['Work Address','work'],
                         ['VIP Number', 'vip' ],
                         ['Tags','tags']
                       ]

    @segment= session[:et]
    session[:members_table_segment] ||= {} 

    current_segment = MarketSegment.new(:segment_type => 'members',:options => session[:members_table_segment])

     @member_count = current_segment.target_count
    
  end
  
  def generate_file
     session[:members_table_segment] ||= {} 
  
    
     worker_key = MiddleMan.new_worker(:class => :member_export_worker,
                                      :args => { :domain_id => DomainModel.active_domain_id,
                                                 :export_options => (params[:export] || {})[:include],
                                                 :export_segmentation => session[:members_table_segment]
                                               })
    session[:member_download_worker_key] = worker_key
    
    render :nothing => true
  end
  
  def status
    if(session[:member_download_worker_key]) 
      worker = MiddleMan.worker(session[:member_download_worker_key])
      
      @completed = worker.results[:completed] || false
    end
  end
  
  def download_file
    if(session[:member_download_worker_key]) 
      worker = MiddleMan.worker(session[:member_download_worker_key])
      send_file(worker.results[:filename],
          :stream => true,
	  :type => "text/" + worker.results[:type],
	  :disposition => 'attachment',
	  :filename => sprintf("%s_%d.%s",'Email_Targets'.t,Time.now.strftime("%Y_%m_%d"),worker.results[:type])
	  )
	  
	  
      session[:member_download_worker_key] = nil
      worker.delete
    else
      render :nothing => true
    end
  
  end
end
