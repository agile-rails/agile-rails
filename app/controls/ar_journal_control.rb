#--
# Copyright (c) 2024+ Damjan Rems
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#+

######################################################################
# Controls for displaying journal table.
######################################################################
module ArJournalControl

######################################################################
# Default filter for journal.
# If filter value is delimited with ; then filter is called from info
######################################################################
def default_filter
  order = agile_sort_options(ArJournal) || { id: :desc }
  filter = session.dig(:filters, 'ar_journal', :filter)
  if filter
    if filter[:value].match(';')
      table, id = filter[:value].split(';')
      return ArJournal.where(tables: table, record_id: id.to_i)
    else
      return agile_filter_options(ArJournal).order(order)
    end
  end
  ArJournal.all.order(order)
end

end
