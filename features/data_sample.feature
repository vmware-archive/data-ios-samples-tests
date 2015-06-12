Feature: Running a sample app
  As an iOS developer
  I want to have a sample app
  So I can begin developing quickly

Scenario: Fetching for the first time
  Given I am on the Welcome Screen
  Then I touch "Fetch"
  And I wait for "Password Flow" to appear
  Then I clear input field number 1
  Then I enter my username into input field number 1
  Then I clear input field number 2
  Then I enter my password into input field number 2
  And I touch "Password Flow"
  And I wait for "Error Code 404" to appear 
  Then take picture

Scenario: Save, Fetch, Delete with a token already retrieved
  Given I am on the Welcome Screen
  Then I enter "some testing string" into input field number 1
  Then I touch "Save"
  Then I clear input field number 1
  Then I touch "Fetch"
  And I wait for "some testing string" to appear
  Then I touch "Delete"
  Then I touch "Fetch"
  And I wait for "Error Code 404" to appear
  Then take picture

Scenario: Logout button
  Given I am on the Welcome Screen
  Then I touch "Logout"
  Then I touch "Fetch"
  And I wait for "Password Flow" to appear
  Then take picture
