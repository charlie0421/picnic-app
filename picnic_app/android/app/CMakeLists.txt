cmake_minimum_required(VERSION 3.4.1)

add_library(dummy SHARED src/main/cpp/dummy.cpp)
find_library(log-lib log)
target_link_libraries(dummy ${log-lib})