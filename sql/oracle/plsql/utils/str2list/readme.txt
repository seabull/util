Files:

str2list.pkg - source code for strlist parsing mechanism
filepath1.pkg and filepath2.pkg - examples of usage, explained briefly below

Examples:

The filepath1.pkg uses str2list to parse a path string; 
in this case, it declares the collection in the package specification, 
so it can be accessed directly. Here is a test usage:

@filepath1.pkg

BEGIN
   fileio.setpath ('a;b;c;d;efg;;');
   str2list.showlist ('fileio', 'dirs');
END;
/

The filepath2.pkg also uses str2list to parse a path string; 
in this case, however, it declares the collection in the package body 
and provides programs to manipulate the collection. Here is a test usage:

@filepath2.pkg

BEGIN
   fileio.setpath ('a;b;c;d;efg;;');
   str2list.showlist ('fileio', 'first', 'next', 'nthval', 'pl');
END;
/ 
