# Real-world Spring performance improvements that won’t take a toll!

### Abstract

Join us on a journey to uncover real-world performance improvements in this live demo session.  We’ll start with a Spring Boot 2.7 application running on JDK 11, much like an application that many of you probably have in production today.  This application processes cars passing through a toll gate on a major US highway, looking up their accounts, processing the toll charge, and using AI vision to check that the vehicle matches the one that the toll account is registered to (same color, same style of vehicle, etc.)

But this application has poor performance!  What can we do?

Together, we’ll use all the tools at our disposal to figure out what is causing the problem.  We’ll use observability tools like metrics to observe trends, we’ll drill down into distributed traces to find out what is happening inside the application, including all the way down into the bowels of the database to see how the queries are being executed.  I’m sure we’ll find opportunities to optimize, and we’ll make those changes live.

We’ll also take advantage of OpenRewrite recipes to migrate our application up to the latest and greatest Spring Boot 3.x version, and the much newer JDK 21 so we can take advantage of virtual threads.  We’ll even try using a GraalVM native image!  Of course, we’ll want to test those changes, and we’ll be sure to use Spring’s excellent support for Testcontainers to do that before we promote our changes to production.

In the end, I’m sure we will achieve some great results together and dramatically improve the performance of our application, and we’ll use our observability tools to quantify the impact.  We hope to see you there!

