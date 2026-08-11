package main

approved_base_images := {
  "golang",
  "gcr.io/distroless/static",
  "gcr.io/distroless/base",
  "alpine",
}

deny[msg] {
  input[i].Cmd == "from"
  image := input[i].Value[0]
  not any_approved(image)
  msg := sprintf("base image '%s' is not in the approved list: %v", [image, approved_base_images])
}

deny[msg] {
  input[i].Cmd == "user"
  val := lower(input[i].Value[0])
  val == "root"
  msg := "Dockerfile must not set USER to root"
}

deny[msg] {
  not has_nonroot_user
  msg := "Dockerfile must set a non-root USER"
}

deny[msg] {
  input[i].Cmd == "run"
  contains(input[i].Value[0], "sudo")
  msg := sprintf("Dockerfile must not use sudo: %s", [input[i].Value[0]])
}

has_nonroot_user {
  input[i].Cmd == "user"
  val := lower(input[i].Value[0])
  val != "root"
  val != "0"
}

any_approved(image) {
  prefix := approved_base_images[_]
  startswith(image, prefix)
}
