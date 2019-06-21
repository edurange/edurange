# Controller Files
---                                                                                                                

Updated 5/7/18

These may not be complete and may need more testing.

### This file contains a basic description of all the files in this directory:  
 - admin_controller.rb: Controller for all admin level users. Has the following functions:
   - Index has two variables, instructors and students, as well as some AWS stuff(Makred for refactoring)
   - Create a new instructor
   - Reset a user's password
   - Delete a user
   - Promote a student to an instructor
   - Add all student to a group
   - Demote an instructor to a student
   - Create a new student group
   - Remove a student group
   - Add a user to a stubnet group
   - Remove a user from a student group	
 
 - application_controller.rb: Base controller for all other controllers. 
   - Has helper method nat_instance (Marked for refactoring)
   - Private 
     - Nat instance (Marked for refactoring)
     - User not authorized alert method and reirect to referrer root path
     - Authenticate Admin when logging in
     - Authenticate Instructor when logging in
     - Authenticate Admin or Instructor when logging in
     - Authenticate Student

 - home_controller.rb: Controller for the homepage. If the user is signed in then it redirects to that user's homepage and if not, redirects to the new user setssion path.
   - Just has an index method for determining and redirecting traffic to the appropriet page as mentioned in the above description
     
 - instructor_controller.rb: Controller for all instructor level users. Has the following functions:
   - Index has variable players
   - Create student groups
   - Destroy student groups
   - Add a user to a student group
   - Remove a user from a student group
   - Set a student group(Needs more description)
   
 - management_controller.rb: For managing the database
   - Clean cleans the database
   - Purge purges the database
   
 - registration_controller.rb: Controller for registering new users (I will come back to this one)
 
 - scenarios_controller.rb: Controller for handling scenarios(A lot of the functionality is handled by javascript functions)
   - *This file is only partially commented as most of the function names are self explanetory and/or call javascript fuctions*
    
   
- schedules_controller.rb: Controller for scheduling scenarios for student groups
  - Sets up the show edit update and destroy actions and authenticates if user is an admin or an instructor
  - Index shows all the schedules
  - Show is empty
  - New creates a new schedule
  - Edit is empty
  - Create allows the user to create a new schedule with the given parameters and saves it to the database
  - Update allows the user to update a schedule's information
  - Destroy destroys schedule
  - Private
    - set_schedule
    - schedule_params
    
- scoring_controller.rb: Handles scoring but the code is currently insecure right now and need to be fixed so it is all commented ot

- student_controller.rb: 
  - Authenticates student, sets the user, and sets the scenario, answer, and question for the student level so they don't have access to instructor and admin level abilities.
  - Index displays the student's scenarios
  - Handles student answers for scenarios(string, number, essay)
  - Private
    - set the current user(get the specific student user from the database)
    - Set the scenarios for the current user
    - Set the questions and answers for the scenario for the student

- student_group_controller.rb: All functionality has be moved to the instructor controller and is thus commented out

- tutorials_controller.rb: 
  - Index and making_scenarios do nothing
  - Send to the user student or faculty manuals with instructor_manual and student_manual respectively

- user_controller.rb: 
  - Index authorizes all users
  - Show shows all the current user's info if the user is an adminor the current user otherwise there is an alert and access is denied
  - Update updates a users attributes after finding and authorizing that user
  - Destroy destroys a user unless that user is the current user
  - Private
     - Uses secure params
