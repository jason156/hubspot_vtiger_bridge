require 'json'
require 'uri'
require 'tzinfo'
require File.dirname(__FILE__) + '/vtiger_lead_custom_fields'
require File.dirname(__FILE__) + '/vtiger_event_custom_fields'

module HubspotWebhooksAdapter
  VTIGER_TIMEZONE = ENV['VTIGER_TIMEZONE'] || 'America/Montreal'
  
  def HubspotWebhooksAdapter.to_vtiger_lead hubspot_lead
    lead_link = remove_url_protocol hubspot_lead['publicLeadLink']
    {'firstname' => hubspot_lead['firstName'] || '', 
      'lastname' => hubspot_lead['lastName'] || '', 
      'company' => hubspot_lead['company'] || '', 
      'email' => hubspot_lead['email'] || '', 
      VTigerLeadCustomFields::HUBSPOT_LEAD_ID => hubspot_lead['guid'] || '', 
      VTigerLeadCustomFields::HUBSPOT_INDUSTRY => hubspot_lead['industry'] || '', 
      VTigerLeadCustomFields::HUBSPOT_PUBLIC_URL => lead_link,
      'phone' => hubspot_lead['phone'] || '',
      VTigerLeadCustomFields::HUBSPOT_MESSAGE => hubspot_lead['message'] || '',
      'designation' => hubspot_lead['jobTitle'] || '',
      'website' => hubspot_lead['website'] || ''
      }
  end
  
  def HubspotWebhooksAdapter.extract_event hubspot_lead
    conversion_event = hubspot_lead['lastConversionEvent']
    
    if conversion_event
      timezone = TZInfo::Timezone.get(VTIGER_TIMEZONE)
      vtiger_local_date = timezone.strftime('%d-%m-%Y', Time.at(conversion_event['convertDate']/1000).utc)
      vtiger_local_time = timezone.strftime('%H:%M', Time.at(conversion_event['convertDate']/1000).utc)
      {'subject' => 'Website form filled', 
       'eventstatus' => 'Held', 
       'activitytype'=> 'Undefined', 
       'description' => 'Form name: ' + (conversion_event['formName']),
       'date_start' => vtiger_local_date,
       'time_start' => vtiger_local_time,
       'due_date' => vtiger_local_date,
       'time_end' => vtiger_local_time,
       'duration_hours' => 0,
       VTigerEventCustomFields::HUBSPOT_FORM_URL => remove_url_protocol(conversion_event['url'])
      }
    end
  end
  
  def HubspotWebhooksAdapter.remove_url_protocol url_with_protocol
    url_without_protocol = ''
    if !url_with_protocol.nil? and !url_with_protocol.empty? 
      url = URI.parse(URI.escape(url_with_protocol))
      url_without_protocol = url.host
      url_without_protocol += (url.path || '')
      url_without_protocol += ('?' + url.query) if url.query
    end
    url_without_protocol
  end
end