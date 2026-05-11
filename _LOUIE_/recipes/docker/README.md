Docker build, push, and deploy recipes for projects shipping single-image containerised workloads.

Recipes in this section assume the project ships as one Docker image to one registry, deployed to one (or a small number of) long-lived server(s). They cover Dockerfile authorship, dev-side build-and-push, and server-side pull-and-restart. Orchestrators (Kubernetes, ECS, Cloud Run, Nomad) and multi-image stacks are out of scope — those warrant their own recipes if and when they're added.
