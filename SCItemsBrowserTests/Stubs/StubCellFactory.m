#import "StubCellFactory.h"

@implementation StubCellFactory

-(UITableViewCell<SCItemCell>*)createCellForListMode
{
    return nil;
}

-(UICollectionViewCell<SCItemCell>*)createCellForGridMode
{
    return nil;
}

@end