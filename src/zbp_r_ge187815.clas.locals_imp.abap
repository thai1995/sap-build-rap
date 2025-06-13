CLASS lsc_zr_ge187815 DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

ENDCLASS.

CLASS lsc_zr_ge187815 IMPLEMENTATION.

  METHOD save_modified.
    DATA: lt_shoppingcarts    TYPE STANDARD TABLE OF zge187815,
          ls_shoppingcart     TYPE zge187815,
          events_to_be_raised TYPE TABLE FOR EVENT zr_ge187815~statusUpdated.

    IF create-shoppingcart IS NOT INITIAL.
      LOOP AT create-shoppingcart ASSIGNING FIELD-SYMBOL(<fs_create_shoppingcart>).
        IF <fs_create_shoppingcart>-%control-OverallStatus = if_abap_behv=>mk-on
          AND <fs_create_shoppingcart>-OverallStatus = zbp_r_ge187815=>order_state-saved.
          zcl_ge187815_start_bgpf=>run_via_bgpf_tx_uncontrolled( i_rap_bo_key = <fs_create_shoppingcart>-OrderUuid ).
        ENDIF.
      ENDLOOP.
    ENDIF.

    " The salesorder and the status us updated via BGPF
    IF update-shoppingcart IS NOT INITIAL.
      LOOP AT update-shoppingcart ASSIGNING FIELD-SYMBOL(<fs_update_shoppingcart>).
        IF <fs_update_shoppingcart>-%control-SalesOrderStatus = if_abap_behv=>mk-on.
          CLEAR events_to_be_raised.
          APPEND INITIAL LINE TO events_to_be_raised.
          events_to_be_raised[ 1 ] = CORRESPONDING #( <fs_update_shoppingcart> ).
          RAISE ENTITY EVENT zr_ge187815~statusUpdated FROM events_to_be_raised.
        ENDIF.
        IF <fs_update_shoppingcart>-%control-OverallStatus = if_abap_behv=>mk-on
          AND <fs_update_shoppingcart>-OverallStatus = zbp_r_ge187815=>order_state-saved.
          zcl_ge187815_start_bgpf=>run_via_bgpf_tx_uncontrolled( i_rap_bo_key = <fs_update_shoppingcart>-OrderUuid ).
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

ENDCLASS.

CLASS lhc_zr_ge187815 DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS:
      get_global_authorizations FOR GLOBAL AUTHORIZATION
        IMPORTING
        REQUEST requested_authorizations FOR ShoppingCart
        RESULT result,
      setStatusToNew FOR DETERMINE ON MODIFY
        IMPORTING keys FOR ShoppingCart~setStatusToNew.

    METHODS calculateOrderID FOR DETERMINE ON SAVE
      IMPORTING keys FOR ShoppingCart~calculateOrderID.

    METHODS setStatusToSave FOR DETERMINE ON SAVE
      IMPORTING keys FOR ShoppingCart~setStatusToSave.
    METHODS validateOrderedItem FOR VALIDATE ON SAVE
      IMPORTING keys FOR ShoppingCart~validateOrderedItem.

    METHODS validateOrderQuantity FOR VALIDATE ON SAVE
      IMPORTING keys FOR ShoppingCart~validateOrderQuantity.

    METHODS validateRequestedDeliveryDate FOR VALIDATE ON SAVE
      IMPORTING keys FOR ShoppingCart~validateRequestedDeliveryDate.
ENDCLASS.

CLASS lhc_zr_ge187815 IMPLEMENTATION.
  METHOD get_global_authorizations.
  ENDMETHOD.
  METHOD setStatusToNew.
    DATA update TYPE TABLE FOR UPDATE zr_ge187815\\ShoppingCart.
    DATA update_line TYPE STRUCTURE FOR UPDATE zr_ge187815\\ShoppingCart.

    READ ENTITIES OF zr_ge187815 IN LOCAL MODE
      ENTITY ShoppingCart
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(entities).
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<fs_entity>) WHERE OverallStatus IS INITIAL.
      update_line-%tky = <fs_entity>-%tky.
      update_line-OverallStatus = zbp_r_ge187815=>order_state-new.
      APPEND update_line TO update.
    ENDLOOP.

    MODIFY ENTITIES OF zr_ge187815 IN LOCAL MODE
      ENTITY ShoppingCart
      UPDATE FIELDS ( OverallStatus )
      WITH update
      REPORTED DATA(update_reported).
    reported = CORRESPONDING #( DEEP update_reported ).
  ENDMETHOD.

  METHOD calculateOrderID.
    DATA update TYPE TABLE FOR UPDATE zr_ge187815\\ShoppingCart.
    DATA update_line TYPE STRUCTURE FOR UPDATE zr_ge187815\\ShoppingCart.

    READ ENTITIES OF zr_ge187815 IN LOCAL MODE
      ENTITY ShoppingCart
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(entities).

    DELETE entities WHERE OrderId IS NOT INITIAL.
    CHECK entities IS NOT INITIAL.

    SELECT MAX( order_id ) FROM zge187815 INTO @DATA(max_object_id).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<fs_entity>) WHERE OrderId IS INITIAL.
      update_line-%tky =  <fs_entity>-%tky.
      update_line-OrderId = max_object_id + 1.
      APPEND update_line TO update.
    ENDLOOP.

    MODIFY ENTITIES OF zr_ge187815 IN LOCAL MODE
      ENTITY ShoppingCart
      UPDATE FIELDS ( OrderId )
      WITH update
      REPORTED DATA(update_reported).
    reported = CORRESPONDING #( DEEP update_reported ).
  ENDMETHOD.

  METHOD setStatusToSave.
    DATA update TYPE TABLE FOR UPDATE zr_ge187815\\ShoppingCart.
    DATA update_line TYPE STRUCTURE FOR UPDATE zr_ge187815\\ShoppingCart.

    READ ENTITIES OF zr_ge187815 IN LOCAL MODE
      ENTITY ShoppingCart
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(entities).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<fs_entity>) WHERE OverallStatus = zbp_r_ge187815=>order_state-new.
      update_line-%tky =  <fs_entity>-%tky.
      update_line-OverallStatus = zbp_r_ge187815=>order_state-saved.
      APPEND update_line TO update.
    ENDLOOP.

    MODIFY ENTITIES OF zr_ge187815 IN LOCAL MODE
      ENTITY ShoppingCart
      UPDATE FIELDS ( OverallStatus )
      WITH update
      REPORTED DATA(update_reported).
    reported = CORRESPONDING #( DEEP update_reported ).
  ENDMETHOD.

  METHOD validateOrderedItem.
    READ ENTITIES OF zr_ge187815 IN LOCAL MODE
      ENTITY ShoppingCart
      FIELDS ( OrderedItem )
      WITH CORRESPONDING #( keys )
      RESULT DATA(entities).
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<fs_entity>).
      APPEND VALUE #( %tky    = <fs_entity>-%tky
              %state_area = 'VALIDATE_ORDERED_ITEM' ) TO reported-shoppingcart.
      IF <fs_entity>-OrderedItem IS INITIAL.
        APPEND VALUE #( %tky = <fs_entity>-%tky ) TO failed-shoppingcart.
        APPEND VALUE #( %tky        = <fs_entity>-%tky
                %state_area     = 'VALIDATE_ORDERD_ITEM'
                %msg        = NEW zcx_ac_exceptions(
                            textid    = zcx_ac_exceptions=>enter_order_item
                            severity  = if_abap_behv_message=>severity-error )
                %element-ordereditem  = if_abap_behv=>mk-on ) TO reported-shoppingcart.
      ENDIF.

      DATA lo_product_api TYPE REF TO zcl_product_api.
      DATA lt_business_data TYPE zcl_product_api=>t_business_data_external.

      DATA filter_conditions  TYPE if_rap_query_filter=>tt_name_range_pairs.
      DATA ranges_table       TYPE if_rap_query_filter=>tt_range_option.

      lo_product_api = NEW #(  ).

      ranges_table = VALUE #( ( sign = 'I' option = 'EQ' low = <fs_entity>-OrderedItem ) ).
      filter_conditions = VALUE #( ( name = 'PRODUCT' range = ranges_table ) ).

      TRY.
          lo_product_api->get_products(
            EXPORTING
              it_filter_cond    = filter_conditions
              top               = 50
              skip              = 0
            IMPORTING
              et_business_data  = lt_business_data
          ).

          IF lt_business_data IS INITIAL.
            APPEND VALUE #( %tky                  = <fs_entity>-%tky
                            %state_area           = 'VALIDATE_ORDERD_ITEM'
                            %msg                  = NEW zcx_ac_exceptions(
                                                          textid      = zcx_ac_exceptions=>product_unkown
                                                          severity    = if_abap_behv_message=>severity-error )
                            %element-ordereditem  = if_abap_behv=>mk-on ) TO reported-shoppingcart.
          ENDIF.
        CATCH cx_root INTO DATA(exception).
          DATA(error_message) = cl_message_helper=>get_latest_t100_exception( exception )->if_message~get_longtext( ).
          APPEND VALUE #( %tky                  = <fs_entity>-%tky
                          %state_area           = 'VALIDATE_ORDERD_ITEM'
                          %msg                  = me->new_message_with_text(
                                                        text = error_message
                                                        severity = if_abap_behv_message=>severity-error )
                          %element-ordereditem  = if_abap_behv=>mk-on ) TO reported-shoppingcart.
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateOrderQuantity.
    READ ENTITIES OF zr_ge187815 IN LOCAL MODE
      ENTITY ShoppingCart
      FIELDS ( OrderQuantity )
      WITH CORRESPONDING #( keys )
      RESULT DATA(entities).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<fs_entity>).
       APPEND VALUE #( %tky    = <fs_entity>-%tky
              %state_area = 'VALIDATE_ORDER_QUANTITY' ) TO reported-shoppingcart.
        IF <fs_entity>-OrderQuantity IS INITIAL.
          APPEND VALUE #( %tky = <fs_entity>-%tky ) TO failed-shoppingcart.
          APPEND VALUE #( %tky        = <fs_entity>-%tky
                %state_area     = 'VALIDATE_ORDER_QUANTITY'
                %msg        = NEW zcx_ac_exceptions(
                            textid    = zcx_ac_exceptions=>enter_order_quantity
                            severity  = if_abap_behv_message=>severity-error )
                %element-orderquantity  = if_abap_behv=>mk-on ) TO reported-shoppingcart.
        ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateRequestedDeliveryDate.
    READ ENTITIES OF zr_ge187815 IN LOCAL MODE
      ENTITY ShoppingCart
      FIELDS ( RequestedDeliveryDate )
      WITH CORRESPONDING #( keys )
      RESULT DATA(entites).

    LOOP AT entites ASSIGNING FIELD-SYMBOL(<fs_entity>).
      APPEND VALUE #( %tky    = <fs_entity>-%tky
              %state_area = 'VALIDATE_DATES' ) TO reported-shoppingcart.
      IF <fs_entity>-RequestedDeliveryDate IS INITIAL.
        APPEND VALUE #( %tky = <fs_entity>-%tky ) TO failed-shoppingcart.
        APPEND VALUE #( %tky        = <fs_entity>-%tky
                %state_area     = 'VALIDATE_DATES'
                %msg        = NEW zcx_ac_exceptions(
                            textid    = zcx_ac_exceptions=>enter_requested_delivery_date
                            severity  = if_abap_behv_message=>severity-error )
                %element-requesteddeliverydate  = if_abap_behv=>mk-on ) TO reported-shoppingcart.
      ELSEIF <fs_entity>-RequestedDeliveryDate < cl_abap_context_info=>get_system_date( ).
        APPEND VALUE #( %tky = <fs_entity>-%tky ) TO failed-shoppingcart.
        APPEND VALUE #( %tky        = <fs_entity>-%tky
                %state_area     = 'OUTDATED_DATES'
                %msg        = NEW zcx_ac_exceptions(
                            textid    = zcx_ac_exceptions=>out_dated_req_delivery_date
                            severity  = if_abap_behv_message=>severity-error )
                %element-requesteddeliverydate  = if_abap_behv=>mk-on ) TO reported-shoppingcart.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
