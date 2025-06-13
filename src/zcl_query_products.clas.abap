CLASS zcl_query_products DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.
    TYPES t_business_data_external TYPE TABLE OF zi_vh_products.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_query_products IMPLEMENTATION.
  METHOD if_rap_query_provider~select.
    DATA business_data TYPE t_business_data_external.
    DATA product_api TYPE REF TO zcl_product_api.
    DATA max_index TYPE i value 0.

    product_api = NEW #(  ).

    DATA(top) = io_request->get_paging(  )->get_page_size(  ).
    DATA(skip) = io_request->get_paging(  )->get_offset(  ).
    DATA(requested_fields) = io_request->get_requested_elements(  ).
    DATA(sort_order) = io_request->get_sort_elements(  ).

    TRY.
        DATA(filter_condition) = io_request->get_filter(  )->get_as_ranges(  ).
        DATA(filter_condition_string) = io_request->get_filter(  )->get_as_sql_string(  ).

        product_api->get_products(
            EXPORTING
                it_filter_cond = filter_condition
                top = CONV i( top )
                skip = CONV i( skip )
            IMPORTING
                et_business_data = business_data
        ).

        IF top IS NOT INITIAL.
            max_index = top + skip.
        ENDIF.

        SELECT * FROM @business_data as data_source_fields
            WHERE (filter_condition_string)
            INTO TABLE @business_data
            UP TO @max_index ROWS.

        if skip is not initial.
            DELETE business_data to skip.
        endif.

        io_response->set_total_number_of_records( lines( business_data ) ).
        io_response->set_data( business_data ).

      CATCH cx_root INTO DATA(exception).
        DATA(exception_message) = cl_message_helper=>get_latest_t100_exception( exception )->if_message~get_longtext( ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
