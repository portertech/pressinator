name "vagrant"
description "Role for testing Pressinator"
run_list("recipe[pressinator::test]")
