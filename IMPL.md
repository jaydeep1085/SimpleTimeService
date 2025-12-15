Task 1 - Minimalist Application Development / Docker / Kubernetes
Tiny App Development: 'SimpleTimeService'
Create a simple microservice (which we will call "SimpleTimeService") in any programming language of your choice: Go, NodeJS, Python, C#, Ruby, whatever you like.
The application should be a web server that returns a pure JSON response with the following structure, when its / URL path is accessed:
{
  "timestamp": "<current date and time>",
  "ip": "<the IP address of the visitor>"
}
Dockerize SimpleTimeService
Create a Dockerfile for this microservice.
Your application MUST be configured to run as a non-root user in the container.
Build SimpleTimeService image
Publish the image to a public container registry (for example, DockerHub) so we can pull it for testing.
Push your code to a public git repository
Push your code to a public git repository in the platform of your choice (e.g. GitHub, GitLab, Bitbucket, etc.). MAKE SURE YOU DON'T PUSH ANY SECRETS LIKE API KEYS TO A PUBLIC REPO!
We have a recommended repository structure here.
Acceptance Criteria
Your task will be considered successful if a colleague is able to build/run your container, and the application gives the correct response.

docker build must be the only command needed to build your container, and docker run must be the only command needed to run your container. Your container must run and stay running.

Other criteria for evaluation will be:

Documentation: you MUST add a README file with instructions to deploy your application.
Code quality and style: your code must be easy for others to read, and properly documented when relevant.
Container best practices: your container image should be as small as possible, without unnecessary bloat.
Container best practices: your application MUST be running as a non-root user, as specified in the exercise.
