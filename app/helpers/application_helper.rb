module ApplicationHelper

  def separate_semicolons options={}
    options[:document] # the original document
    options[:field] # the field to render
    options[:value] # the value of the field

  end

  def line_break_multi options={}
    options[:document] # the original document
    options[:field] # the field to render
    options[:value] # the value of the field
         
    field = ''
    
    options[:value].each do |value|
      field << value + "<br />"
    end
   
    field.html_safe

  end
end
