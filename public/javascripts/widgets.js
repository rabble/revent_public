if( rEvent === undefined ) { var rEvent = function() { return { }; }; }

rEvent.display = ( function() {
  var self =  {
    item: function( item ) {
      var item_container = $(document.createElement('div'));
      if ( !(item.category_id === null)) {
        item_container.addClassName('category_'+item.category_id); 
      }
      var title = $(document.createElement('h4')).addClassName('revent_title title' ).update( item.name );
      var description = $(document.createElement('p')).addClassName('revent_desc desc').update( ( item.description || "" ) );
      var location = $(document.createElement('div')).addClassName('revent_location location').update( ( item.city || "" ) + ", " + ( item.state || "" ) );
      var start_date = $(document.createElement('div')).addClassName('revent_date date').update( ( item.start_date || "" ) );
      item_container.appendChild( title );
      item_container.appendChild( start_date );
      item_container.appendChild( location );
      item_container.appendChild( description );
      return item_container;
    },
    list: function( items, display_id ) {
      // default id is revent_list
      if ( display_id === undefined ) { display_id = 'revent_list' };

      // create a display container unless one already exists
      if ( $(display_id) === null ) { 
        var container = $(document.createElement('div'));
        container.id = display_id;
        document.appendChild( container );
      } else {
        var container = $(display_id);
        container.innerHTML = '';
      }
      
      items.each( function(item) {
        container.appendChild( rEvent.display.item( item ) );
      } );
    }
  };
  return self;
})();
