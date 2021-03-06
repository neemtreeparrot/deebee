require(rJava)
require(RJDBC)
require(dplyr)

#' @title Runs a SQL query in Oracle
#' @description Runs a SQL query in Oracle and returns a resultset.
#' @param query SQL Query to execute.
#' @param host_name Host name.
#' @param port Port name. Defaults to port 1521.
#' @param sid Service Id. Defaults to xe.
#' @param user_name User name for the connection in plain text.
#' @param pwd Password for the connection in plain text.
#' @return SQL resultset in a tibble
#' @examples
#' OraRun_("SELECT * FROM ALL_TABLES", "localhost", 1521, xe, "sc", "tiger")
#'
OraRun_ <-
  function (query,
            host_name,
            port = "1521",
            sid = "xe",
            user_name,
            pwd) {

    # requires libary RJDBC
    jdbcDriver <-
      RJDBC::JDBC(driverClass = "oracle.jdbc.OracleDriver", classPath =  Sys.getenv("ojdbcfile"))


    # open connection
    jdbcConnection <-
      RJDBC::dbConnect(
        jdbcDriver,
        paste0("jdbc:oracle:thin:@", host_name, ":", port, ":", sid),
        user_name,
        pwd
      )

    # execute query
    resultset <- tibble::as_data_frame(RJDBC::dbGetQuery(jdbcConnection, query))

    # close connection
    RJDBC::dbDisconnect(jdbcConnection)
    resultset
  }


#' @title Runs a SQL query in preferred environment.
#' @description Runs a SQL query in Oracle and returns a resultset.
#' @param query SQL Query to execute.
#' @param env Environment name as string. The function will parse the environment name to its equivalent connection string stored under ora_connstr_[env]. This connection must be defined in advance that must contain five variables host_name, port, sid, user_name, pwd. Defaults to environment dev.
#' E.g., ora_connstr_dev <- list(host_name = "localhost", port = "1521", sid = "xe", user_name = "sc", pwd = "tiger")
#'
#' @return SQL resultset as a tibble
#' @examples
#' ora_connstr_dev <- list(host_name = "localhost", port = "1521", sid = "xe", user_name = "sc", pwd = "tiger")
#' OraRun("SELECT * FROM ALL_TABLES", "dev")
#'
OraRun <- function(query, env = "dev")
{
  eval(parse(text = paste0("conn_str = ora_connstr_", env)))
  OraRun_(query, conn_str["host_name"], conn_str["port"], conn_str["sid"], conn_str["user_name"], conn_str["pwd"])
}


#' @title Gets table description from Oracle db
#' @description Table description of an Oracle table is retrieved in a concise format.
#'
#' @param db_table Name of the database table.
#' @param env Environment string to use for forming the connection string.
#' @return Returns a data frame
#'
#' @examples
#' OraTableDesc("EMP", "dev")
OraTableDesc <- function(db_table, env = "dev") {
  OraRun(sprintf("SELECT * FROM ALL_TAB_COLS WHERE TABLE_NAME = '%s'", stringr::str_to_upper(db_table)), env) %>%
    mutate(
      table_column = sprintf(
        "%s.%s[%s(%s,%s)] %s",
        OWNER,
        TABLE_NAME,
        DATA_TYPE,
        DATA_PRECISION,
        DATA_SCALE,
        if_else(NULLABLE == "Y", 'NULL', 'NONULL')
      )
    ) %>%
    select(table_column)

}
