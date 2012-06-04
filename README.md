Pressinator
===========

Chef cookbook for multi-tenant Wordpress hosting.

Usage
-----

    include_recipe "pressinator"

    pressinator_site "example.com" do
      ftp_user "foo"
      ftp_password "secret"
      db_name "example"
      db_user "bar"
      db_password "secret"
    end
