# Controller Files
---                                                                                                                

Updated 4/27/18                                                                                                    

### This file contains a basic description of all the files in this directory:  
 - admin_controller.rb: Controller for all admin level users. Has the following functions:
   - Index has two variables, instructors and students, as well as some AWS stuff(For david to decypher)
   - Create a new instructor
   - Reset a user's password
   - Delete a user
   - Promote a student to an instructor
   - Add all student to a group
   - Demote an instructor to a student
   - Create a new student group
   - Remove a student group
   - Add a user to a studnet group
   - Remove a user from a student group	
 
 - application_controller.rb: Base controller for all other controllers. 
   - Has helper method nat_instance (Don't know what this does yet)
   - Private 
     - Nat instance (Don't know what this does yet)
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
 
 - scenarios_controller.rb: Controller for handling scenarios (This file is 991 lines long so I will get back to it later)
   - Sets up the scenario, cloud, subnet, instance, group, and role abilities
   - 
  
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
    - set_user
    - schedule_params
    
- scoring_controller.rb: Handles scoring but the code is currently insecure right now and need to be fixed so it is all commented ot


- statistics_controller.rb: (Very long)

- student_controller.rb: 

- student_group_controller.rb: All functionality show be moved to the instructor controller and is thus commented out

- tutorials_controller.rb: 

- user_controller.rb: 
