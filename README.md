# AgileRails

[![Gem Version](http://img.shields.io/gem/v/agile_rails.svg)](https://rubygems.org/gems/agile_rails)
[![Gem Downloads](https://img.shields.io/gem/dt/agile_rails.svg)](https://rubygems.org/gems/agile_rails)


Agile Rails simplifies the programming of corporate Intranet applications. 
Minimal database experience and only basic programming skills are needed 
to create a data entry program. You can do it in 6 simple steps.

Step 1: Know your data and create Rails migration and model<br>
Step 2: Generate Agile Rails form<br>
Step 3: Edit form to your requirements<br>
Step 4: Define Labels and Help Text<br>
Step 5: Create additional logic in Controls File (if required)<br>
Step 6: Include in application menu<br>

Most of the time, you will end up with 3 source files.

<b>Migration:</b>Rails uses migrations to make changes to the database 
schema, such as creating tables or altering columns. 

An example of migration file.
```ruby
class Diary < ActiveRecord::Migration[7.0]
  def change
    create_table :diaries do |t|
      t.string    :title
      t.text      :body
      t.datetime  :time_begin
      t.integer   :duration
      t.text      :search
      t.boolean   :closed, default: true
      t.integer   :ar_user_id

      t.timestamps

      t.index :ar_user_id
    end
  end
end
```

<b>Model:</b> Model's primary purposes is to represent the data and logic 
of the application. It contains business logic, relations between data, validations

An example of a typical model file:

```ruby
class Diary < ApplicationRecord

validates :title,      presence: true
validates :time_begin, presence: true
validates :duration,   presence: true 

before_save :fill_search_field
 
#############################################################################
# Before save remove all html tags from body field and put data into search field.
#############################################################################
def fill_search_field
 text = ActionView::Base.full_sanitizer.sanitize(self.body, :tags=>[]).to_s
 text.gsub!(/\,|\.|\)|\(|\:|\;|\?/,'')
 text.gsub!('&#13;',' ')
 text.gsub!('&gt;',' ')
 text.gsub!('&lt;',' ')
 text.squish!
 
 self.search = (self.title + text).downcase
end

end
```

<b>Form:</b> Agile Rails Form's purpose is to define data entry fields and actions which can be taken on data.
It contains two main sections.

<b>index:</b> Defines view on table data (data_set) and actions that can be performed on 
database documents or set of documents.<br>
<b>form:</b> Defines data entry fields for adding, editing or viewing a database record.<br>

Form is written in the YAML markup language which is human friendly and can be edited with any
text editor.

Example of form file:

```yaml
table: note

index:
  filter: search as text_field
  actions: standard

result_set:
  filter: current_users_documents
  actions:
    1: edit
    2: delete

  columns:
    10:
     name: title
     width: 25%
    20:
      name: time_started
      width: 10%
      format: '%d.%m.%Y'
    30:
      name: duration

form:
  fields:
  10:
    name: user_id
    type: readonly
    eval: dc_name4_id,dc_user,name
    default:
      eval: 'session[:user_id]'    
  20:
    name: title
    type: text_field
    size: 50
  30:
    name: time_started
    type: datetime_picker
    options:
      step: 15
  40:
    name: duration
    type: select
  50:
    name: body
    type: html_field
    options: "height: 500"
```

Add data entry field labels and help text to your project locales files.
```yaml
en:
  helpers:
    label:
      diary:
        table_title: Diary
        choices_for_duration: "10 min:10,15 min:15,20 min:20,30 min:30,45 min:45,1 hour:60,1 hour 30 min:90,2 hours:120,2 hours 30 min:150,3 hours:180,4 hours:240,5 hours:300,6 hours:360,7 hours:420,8 hours:480"

        title: Title
        body: Description
        time_started: Start time
        duration: Duration 
        search: Search
        ar_user_id: Owner

    help:
      diary:
        title: Short title of event
        body: Description of event or note
        time_started: Time or date when note is created or event started
        duration: Duration of event
        search: Body text striped of html code for text searching 
        ar_user_id: Owner of the note
  ```
Combination of two source files and localisation data makes application
data entry program. Application data entry program implements all data
entry operations on a database:<br>
<li>add new document<br>
<li>edit document<br>
<li>delete document<br>
<li>view document

<br><br>Add data entry application into your application menu:

```ruby
agile_link_to('Diary', 'book', { table: 'diary' }, target: 'iframe_edit')
```

And if you need advanced program logic, you can implement it in 
the control file. Control files code is injected into agile
controller during form load and provides additional control logic required
by data entry program. In control files you can control program workflow by
implementing callback methods. 
- *before_new
- new_record
- dup_record
- *before_edit
- *before_save
- after_save
- *before_delete
- after_delete
Methods marked with asterisk can also effect flow of the application. If method return false 
(not nil but FalseClass) normal flow of the program is interrupted and last operation is canceled 

```ruby
######################################################################
# AgileRails controls for Diary database table
######################################################################
module DiaryControl

######################################################################
# Fill in currently logged in user's data on new record action.
######################################################################
def new_record
  @record.user_id = session[:user_id]
  @record.time_started = Time.now.localtime
end

###########################################################################
# Filter only owned documents to logged on user 
###########################################################################
def current_user_documents
  user_filter_options(Note).and(ar_user_id: session[:user_id]).order(id: 'desc')
end

end
```
<br>

## Features
AgileRails uses Ruby on Rails, one of the most popular frameworks for 
building websites. Ruby on Rails guarantees highest level of application security 
and huge base of extensions which will help you when your application grows.
<br><br>
AgileRails is also full-featured CMS which was build to run multiple web sites on single Ruby on Rails instance. 
All sites can share design, data, users ...
<br><br>
AgileRails has built-in admin friendly two level role based application access system. 
On the first level administrator defines roles and roles rights as web site policies. Policies define
if user can view content or not or if user can edit content. Roles are then assigned to users 
and policies are assigned to documents (web content), parts of content, menus ...
<br>
Second level defines roles which can access database data. Each database table can have defined which 
user roles can read, edit, create or delete records in a table.
<br><br>
Integrates journal with options to undo single field
<br><br>
Integrates CK Editor as HTML editor and ElFinder file manager with with drag & drop support through 
agile_rails_html_editor gem.

## Installation

Go and [jumpstart](https://github.com/agile-rails/agile-rails-jumpstart)
internal portal application with AgileRails in just few minutes.

Compatibility
-------------

Technology behind AgileRails is being actively developed since 2012 and has been live tested in production 
since early days. It runs against latest technology Ruby (3.3), Rails (7.1) 
and had so far little or no problems advancing to latest versions of Ruby or Ruby on Rails.

Documentation
-------------

Please see the agile-rails.com website for more information:
[agilerails.zop.si](http://agilerails.zop.si)

License (MIT LICENCE)
---------------------

Copyright (c) 2024+ Damjan Rems

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Credits
-------

Damjan Rems: damjan dot rems at gmail dot com
