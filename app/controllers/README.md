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
  
   
