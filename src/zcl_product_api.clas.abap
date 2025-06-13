CLASS zcl_product_api DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
    TYPES t_business_data_external TYPE TABLE OF zi_vh_products.
    METHODS get_products
      IMPORTING
        it_filter_cond   TYPE if_rap_query_filter=>tt_name_range_pairs   OPTIONAL
        top              TYPE i OPTIONAL
        skip             TYPE i OPTIONAL
      EXPORTING
        et_business_data TYPE t_business_data_external
      RAISING
        /iwbep/cx_cp_remote
        /iwbep/cx_gateway
        cx_web_http_client_error
        cx_http_dest_provider_error
      .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_product_api IMPLEMENTATION.

  METHOD get_products.
    DATA lt_business_data TYPE TABLE OF zsc_ac_api_product_2=>tys_a_clfn_product_type.
    DATA: filter_factory   TYPE REF TO /iwbep/if_cp_filter_factory,
          filter_node      TYPE REF TO /iwbep/if_cp_filter_node,
          root_filter_node TYPE REF TO /iwbep/if_cp_filter_node.

    DATA: http_client        TYPE REF TO if_web_http_client,
          odata_client_proxy TYPE REF TO /iwbep/if_cp_client_proxy,
          read_list_request  TYPE REF TO /iwbep/if_cp_request_read_list,
          read_list_response TYPE REF TO /iwbep/if_cp_response_read_lst.
    " Access to http destination to connect to S4/HANA Cloud
    DATA(http_destination) = cl_http_destination_provider=>create_by_cloud_destination(
                                                            i_name = 'S4HANA_ODATA_Products_ABAP_ReadOnly'
                                                            i_authn_mode = if_a4c_cp_service=>service_specific ).
    " Create http client
    http_client = cl_web_http_client_manager=>create_by_http_destination( i_destination = http_destination ).

    " Create odata client proxy
    odata_client_proxy = /iwbep/cl_cp_factory_remote=>create_v2_remote_proxy(
                                                        io_http_client = http_client
                                                        is_proxy_model_key = VALUE #( repository_id = 'DEFAULT'
                                                                                      proxy_model_id = 'ZSC_AC_API_PRODUCT_2'
                                                                                      proxy_model_version = '0001' )
                                                        iv_relative_service_root = '' ).
    " Navigate to the resource and create a request for the read operation
    read_list_request = odata_client_proxy->create_resource_for_entity_set( 'A_CLFN_PRODUCT' )->create_request_for_read(  ).

    " Create the filter tree
    filter_factory = read_list_request->create_filter_factory(  ).

    " Build filter
    LOOP AT it_filter_cond ASSIGNING FIELD-SYMBOL(<fs_cond>).
      filter_node = filter_factory->create_by_range( iv_property_path = <fs_cond>-name
                                                     it_range = <fs_cond>-range ).
      IF root_filter_node IS INITIAL.
        root_filter_node = filter_node.
      ELSE.
        root_filter_node = root_filter_node->and( filter_node ).
      ENDIF.
    ENDLOOP.

    " Check root_filter_node is not empty
    IF root_filter_node IS NOT INITIAL.
      read_list_request->set_filter( root_filter_node ).
    ENDIF.

    " Set top
    IF top > 0.
      read_list_request->set_top( top ).
    ENDIF.

    read_list_request->set_skip( skip ).

    read_list_response = read_list_request->execute(  ).
    read_list_response->get_business_data( IMPORTING et_business_data = lt_business_data ).
    et_business_data = CORRESPONDING #( lt_business_data ).

  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.
    DATA business_data TYPE t_business_data_external.
    DATA filter_conditions TYPE if_rap_query_filter=>tt_name_range_pairs.
    DATA ranges_table TYPE if_rap_query_filter=>tt_range_option.

    ranges_table = VALUE #(
        ( sign = 'I' option = 'EQ' low = 'MZ-TG-Y240' )
        ( sign = 'I' option = 'BT' low = 'TG' high = 'TH' )
    ).

    filter_conditions = VALUE #( ( name = 'PRODUCT' range = ranges_table ) ).

    TRY.
        get_products(
            EXPORTING
                it_filter_cond = filter_conditions
                top = 2
                skip = 0
            IMPORTING
                et_business_data = business_data
        ).
        out->write( business_data ).
      CATCH cx_root INTO DATA(exception).
        out->write( cl_message_helper=>get_latest_t100_exception( exception )->if_message~get_longtext( ) ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
