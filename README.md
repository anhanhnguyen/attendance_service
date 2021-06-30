# Attendance Service

## Requirement

Create a backend application to record attendance from frontend clients (web / mobile app)
and produce a dashboard for school admins to view important metrics.

## The app is able to:

* Provide the API for the end consumers (web / mobile app) to record attendances via:

  | Category        | Request | Endpoint                               | Function            |
  |-----------------|---------|----------------------------------------|---------------------|
  |     school_path | GET     | /api/schools                           | index               |
  |     school_path | GET     | /api/schools/:id                       | show                |
  |     school_path | POST    | /api/schools                           | create              |
  |     school_path | PATCH   | /api/schools/:id                       | update              |
  |                 | PUT     | /api/schools/:id                       | update              |
  |     school_path | DELETE  | /api/schools/:id                       | delete              |
  |       user_path | GET     | /api/users                             | index               |
  |       user_path | GET     | /api/users/:id                         | show                |
  |       user_path | POST    | /api/users                             | create              |
  |       user_path | PATCH   | /api/users/:id                         | update              |
  |                 | PUT     | /api/users/:id                         | update              |
  |       user_path | DELETE  | /api/users/:id                         | delete              |
  | attendance_path | GET     | /api/attendances                       | index               |
  | attendance_path | GET     | /api/attendances/:id                   | show                |
  | attendance_path | POST    | /api/attendances                       | create              |
  | attendance_path | DELETE  | /api/attendances/:id                   | delete              |
  | attendance_path | GET     | /api/attendances/aggregate/school/:id  | aggregate by school |

* Provide API to get infomation about common metrics:
  
  - School attendance aggregated by day / week / month (present, absent)
    - A user is supposed to be present when
      - Being checking in school when aggregation requests are made
      - Attendace time accumulation is more than 4 hours/day or more than 80% present days for a time period (week/month)
    - Otherwise, user is supposed to be absent

* Background job for attendance data aggregation

  - Supervision tree and worker processes are designed and implemented
    
    Supervisor `AttendenceService.Attendances.Aggregate` supervises:

      - GenServer `AttendenceService.Attendances.AggregateServ`
        *handles requests from `*Controller` and aggregation processes*

      - DynamicSupervisor `AttendenceService.Attendances.AggregateDsup`
        *supervises:*
        
        - GenServer `AttendenceService.Attendances.AggregateWorker`
          *handles aggregating calculation by:*

           - *Chunk large data if needed*
           - *Create child processes to handle chunk data*

      - TaskSupervisor `AttendenceService.Attendances.AggregateTask`
        *supervises calculation tasks*

* Error handling mechanism: using Phoenix default mechanism. The error details sent in responses are just in development mode. There are no sensitive information will be exposed when running the application in production mode.

## Getting started

Docker for development is not fully implemented yet.
The instruction will base on OS development environment.

### Prerequisites

- Elixir v1.10.4
- Phoenix v1.5.4
- Postgres v11.2

Database server is up and running.

To start Postgres using Docker run:
```
 docker run \
    -e POSTGRES_PASSWORD=postgres \
    -e POSTGRES_USER=postgres \
    -e POSTGRES_DB=attendence_service_dev \
    -p 5432:5432 \
    -d postgres
```

### Build and run

To start your Attendance Service server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Implementation details

### App architecture

Attendance Service app: `AttendenceService.Supervisor`
- HTTP connection handling: `AttendenceServiceWeb.Endpoint` (default)
- Messaging: `Phoenix.PubSub.Supervisor` (defalt)
- System monitoring and metric supports: `AttendenceServiceWeb.Telemetry` (default)
- Database connection handling: `AttendenceService.Repo` (default)
- Aggregation handling: `AttendenceService.Attendances.Aggregate`
  - Controller's request routers: `AttendenceService.Attendances.AggregateServ`
  - Aggregation worker supervisor: `AttendenceService.Attendances.AggregateDsup`
  - Task handlers: `AttendenceService.Attendances.AggregateTask`


### Abstract database models

In testing context, the school and user information is kept mininal with:

```
- school
    - id
    - name
    - users
        - id
        - name
```

A school has many users. Each user belongs to only one school.

The attendance information is requested to include:

```
- id
- timestamp
- user_id
- school_id
- temperature
- image
- type (checkin or checkout)
```

An attendance is a representation (checkin/checkout) of one user for one school at a certain moment.

An attendance belongs to only one user and one school.

The temperature is in range of 28&deg;C to 43&deg;C

A school has many attendances.

A user also has may attendances.

### The data flow of requests

The request handling follows default Phoenix request handling model.

1. Endpoint: The request reaches endpoint (`AttendenceServiceWeb.Endpoint`)
2. Router: Based on the endpoint, the corresponding controller is assigned for this request by the router (`AttendenceServiceWeb.Router`)
3. Controller: The handler for the request. Controllers are usually divided based on the context. For example:
    - `AttendenceServiceWeb.SchoolController`
    - `AttendenceServiceWeb.UserController`
    - `AttendenceServiceWeb.AttendanceController`
4. Data handling: The handler triggers the data handling to process data. Data handling varies. They can be database handling and queries such as:
    - `AttendenceService.Repo`
    - `AttendenceService.Schools`
    - `AttendenceService.Users`
    - `AttendenceService.Attendances`

    or calculation like `AttendenceService.Attendances.Aggregate`
5. View: Render the data with the corresponding view when all the necessary queries and calculation are done then send back the response. Views usually assosiate with their controllers such as:
    - `AttendenceServiceWeb.SchoolView`
    - `AttendenceServiceWeb.UserView`
    - `AttendenceServiceWeb.AttendanceController`

### The flow of aggregation data

There are several modules take part in aggregation job.

*All the module refered below are placed under `AttendenceService.Attendances` context*

1. Controller requests data aggregation with `AggregateServ`
2. `AggregateServ` creates a worker under `AggregateDsup` to process data
3. `AggregateWorker` queries data from database
4. Data are chunked by date and assigned as a task under `AggregateTask`
5. When task are done, the result are sent back to `AggregateWorker`
6. `AggregateWorker` inform `AggregateServ` the total report
7. `AggregateServ` returns calculated data for controller

Multi processes are created to accelerate the calculation. By this way, these processes are not blocked by others when some of these steps are taking too long.

All processes are supervised and having proper exception hanlding mechanism by their supervisors.

---

> The orginal design for the aggregation includes the **data cache mechanism** to accelerate the system.
> However, the plan is going off track and the timer is fired so this features cannot be delivered this time.

---

### Populating fake data script

An Erlang application is used to constructed the populating fake data when server is running by sending HTTP requests to the server.

The source code can be found in `tools/data_gen`

To fulfill the data quantity requirements, a massive number of processes are created to send the requests. This reaches the limitation of development resources and causes the crash in shell when executing.

The chosen approach for this is limiting the processes at 1000 and extend the waiting time between executions. This is just the work around in budget.

Another problem found is the random creation of attendances does not meet the acceptance criteria.
It does not make sense when someone has been recorded checking out of school even though she/he does not check in.

To sum up, I think this script is just for testing the server toleration. Improvements are insistently needed.

Many thanks to [shavit/haiku.ex](https://gist.github.com/shavit/5f59fef75d37cba48185113e21a4d3b7) for the seeds used in random name generator.

## Notes

- High fever events are not implemented yet due to the implementation time limitation
- Dashboard frontend UI is also not available as I am not strong for frontend development and the time budget cannot afford for study and research
- A spelling mistake in naming modules as `AttendenceService*` (should be AttendanceService) was just discovered recently and the correction cannot make it in time to be checked in.
- Please checkout `tools/data_gen/README.md` for more information about the script to populate fake data

Ready to run in production? Please [check out on deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
