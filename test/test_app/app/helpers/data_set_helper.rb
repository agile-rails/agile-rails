module DataSetHelper

##############################################################################
# testing how custom method can be called instead of standard data_set data
##############################################################################
def data_set_as_method
  %(<h2>Works</h2>).html_safe
end

end
