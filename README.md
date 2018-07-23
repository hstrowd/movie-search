# README

Movie Search Service - A simple JSON-API web service for searching for movies.

## Setup

This is a Ruby on Rails application and assumes a minimal, working understanding of this framework. For more information on how to setup and work in a Rails application, please review their [public documentation](http://guides.rubyonrails.org/getting_started.html).

The following are some initial environmental dependencies that need to be installed in order to run this application:

* [Git](https://git-scm.com/)
* [Ruby](https://www.ruby-lang.org/)
* [Ruby on Rails](https://rubyonrails.org/)
* [SQLite](https://www.sqlite.org/)
  * v3.24.0 is recommended. Regardless, ensure support for fulltext search tables is include.
* [Bundler](https://bundler.io/)

To setup and run this application, use the following steps:

* Pull down the code base: `git clone ...`
* Install all dependencies: `bundle install`
* Setup the application's database: `bundle exec rake db:create db:migrate`
  * NOTE: The `db:migrate` task must be used instead of `db:setup` since ActiveRecord's schema file is not able to properly record the fulltext search table.
* Load movie data sets (currently only IMDBs top 1000 list): `bundle exec rake load:imdb_top_1000`
  * This command takes a while to complete (~1 second per movie).
  * Currently the design of the application has been heavily optimized toward efficient search and retrieval of movie sets. On account of this, additional steps are required within as part of the loading of this data, extending the processing time for this initial load.
* Run the application server: `bundle exec rails server`

This will launch a development instance of the application server on your local machine, defaulting to port 3000.


## Tests

To execute the test suite, use the following steps:

* Setup/recreate the test DB: `RAILS_ENV=test bundle exec rake db:drop db:create db:migrate`
* Run the full test suite: `bundle exec rspec`

A single test can be run by adding the relative path for the target test file to the end of this command. For example: `bundle exec rspec spec/api/movies_api_spec.rb`


## API Structure

The primary API endpoint exposed by this service is the `GET /api/movies` route which allows a set of movies to be retrieved. This endpoint supports a `filter[search]` request parameter which can be used to apply a wide variety of search criteria to the set of movies to be returned.

This API has been developed in accordance with the [JSON-API](http://jsonapi.org/) standards. This protocol includes support for a robust set of API parameters, including filtering, sorting, eager resource loading, customized response payloads, etc. It also provides a traversable set of response payloads that allow other resources and records to be discovered within the API. It is highly encouraged to become familiar with the basic functionality of this protocol before using the API. To help with this, a set of executable example request payloads have been included in the `docs/apis-examples.paw` file, which can be loaded and executed using [the Paw application](https://paw.cloud/).

Additionally, it's worth noting that since the search functionality is taking advantage of SQLite's full text search capabilities, the structure of the `search` filter should use and can take advantage of the capabilities supported within this type of query. In the future we will want to clearly document and publish the expected structure of this filter, but for the time being please review the [SQLite documentation](https://www.sqlite.org/fts3.html#full_text_index_queries) directly.


## Simplifying Assumptions

* All movies will be uniquely identifiable based on their title.
  * This will allow for movies to be safely de-duped, which will allow the import script to be re-run as needed.
* It is far more important to optimize the movie search/retrieval, as opposed to the import.
  * The frequency with which movies will be fetched far surpasses the frequency of them being imported.
  * For this reason, I am comfortable paying a higher up-front performance cost when importing them in order to keep end-user request times to a minimum.
* Search will be part of a larger general use API.
  * The use of a SQL DB is optimal within a Rails application for supporting the standard set of API operations (e.g. CRUD, filtering, sorting, etc) but is not optimal for complex search algorithms.
  * I have none-the-less opted to use a SQL database with slight adjustments to support full text searches to maintain the ability to support additional API functionality going forward.
  * Ideally a first-class search data store (e.g. Elasticsearch) would be integrated into this service to power the search functionality going forward.


## Proposed Roadmap

This is an initial prototype application. Moving forward the following are additional features worth considering:

* Migrate to First-Class Search DB:
  * A SQL database has been used in this application to expedite the setup of the application and efficiently support a robust API, however for the search functionality a SQL database is not the most efficient option.
  * Instead a first-class search DB, such as Elasticsearch, should be evaluated and integrated into the service to improve the performance and architecture of the application.
* Background Job Processing:
  * Currently the fetching, parsing, and loading of all movie data is being handled in a synchronous manner on a single thread.
  * To better manage the load on a production system, we will want to separate this out into a set of background jobs that can be queued and distributed across workers.
* Optimized Fetching/Parsing/Loading:
  * In addition to offloading the fetching, parsing, and loading of movies into background jobs, there are likely steps that can be taken to further optimize this process and improve it's performance.
  * To start, we'll need to evaluate and identify performance bottlenecks in this process (e.g. HTML fetching, record de-duping, relationships creation/recording, etc) and target these areas explicitly.
* Search Result Highlighting:
  * In addition to returning the set of movies matching the provided search criteria, it may also prove valuable for our users to have insight into what specific content within the movie record matched the provided criteria (e.g. a director's name, a keyword value, a portion of the description).
* Additional Filtering:
  * In addition to the initial `search` filter it would be beneficial to allow users to filter on specific attributes when they are searching on a particular type of information.
  * The JSON-API protocol supports this type of per-attribute filtering out of the box, requiring only configuration to setup and support this capability.
* Additional data points:
  * There are additional data points available within IMDB that may prove valuable (e.g. full cast, full keywords, taglines, production companies, etc).
* Configurable Parsing:
  * Currently the parsing of content from the IMDB top 1000 list and associated movie details pages has been setup in a hard-coded manner.
  * IMDB will at some point change the structure of these pages, breaking our ability to parse and load this content.
  * In preparation for this we should extract the parsing of this content into a set of configurations that can be quickly and easily adjusted as the structure of these pages changes.
* Additional data sources:
  * There are additional data sources with valuable movie information that may be valuable to integrate into the data we're collecting (e.g. rotten tomatoes, wikipedia, etc).
* Tracking & Monitoring:
  * In a production environment we will want to monitor the frequency of searches and search terms used to understand and optimize for the most common use cases.
* Continuous Integration:
  * As part of preparing this service for production use, a CI/CD process should be setup.
* Authentication:
  * In a production environment, we will want to authenticate requests into our API.
  * Setting up QAuth authentication and authorization on this API will allow us to monitor and control individual developer's and application's access to the API.
  * The doorkeeper gem can be used to setup OAuth for this application with easy.
* Formal API Documentation:
  * In preparation for having external developers integrate this API into their applications, it will be important to construct and publish API documentation.
  * This can be done by capturing the API structure in an API documentation format (e.g. API Blueprints, Swagger, etc) and publishing this documentation using an appropriate documentation pipeline for the selected format.
