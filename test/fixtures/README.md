# Fixture provenance

`rails-8.1.4-routes.txt` and `rails-8.1.4-engine.txt` were generated locally
using Rails 8.1.4 `ActionDispatch::Routing::RouteSet` objects and the expanded
routes formatter. They cover ordinary routes and an actual mounted engine.

The `rails-7.1.6-formatter.txt`, `rails-7.2.3.2-formatter.txt`, and
`rails-8.0.5.1-formatter.txt` files were produced by those versions' actual
expanded formatter classes using representative route records and an engine
section. They check output compatibility, not booting full Rails applications.
