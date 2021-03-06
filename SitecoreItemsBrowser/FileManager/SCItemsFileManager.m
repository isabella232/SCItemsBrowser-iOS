#import "SCItemsFileManager.h"

#import "SCItemsLevelRequestBuilder.h"
#import "SCItemsFileManagerCallbacks.h"

#import "SCLevelsHistory.h"
#import "SCLevelResponse.h"
#import "SCLevelUpItem.h"

typedef void(^UpdateHistoryActionBlock)(void);
typedef UpdateHistoryActionBlock (^UpdateHistoryActionFromRequest)( SCReadItemsRequest* );

@interface SCItemsFileManager()

@property ( nonatomic, copy ) SCCancelAsyncOperation cancelLoaderBlock;
@property ( nonatomic ) SCLevelsHistory* levelsHistory;

@end

@implementation SCItemsFileManager
{
    SCExtendedApiSession*          _apiSession;
    id<SCItemsLevelRequestBuilder> _nextLevelRequestBuilder;
}


#pragma mark -
#pragma mark constructors
-(void)dealloc
{
    self.cancelLoaderBlock = nil;
}

-(instancetype)init
{
    [ self doesNotRecognizeSelector: _cmd ];
    return nil;
}

-(instancetype)initWithApiSession:( SCExtendedApiSession* )apiSession
              levelRequestBuilder:( id<SCItemsLevelRequestBuilder> )nextLevelRequestBuilder
{
    NSParameterAssert( nil != apiSession );
    NSParameterAssert( nil != nextLevelRequestBuilder );
    
    self = [ super init ];
    
    if ( nil == self )
    {
        return nil;
    }
    
    self->_apiSession = apiSession;
    self->_nextLevelRequestBuilder = nextLevelRequestBuilder;
    self->_levelsHistory = [ SCLevelsHistory new ];
    
    return self;
}


#pragma mark -
#pragma mark Public
-(BOOL)isRootLevelLoaded
{
    return [ self->_levelsHistory isRootLevelLoaded ];
}

-(void)loadLevelForItem:( SCItem* )item
              callbacks:( SCItemsFileManagerCallbacks* )callbacks
          ignoringCache:( BOOL )shouldIgnoreCache
{
    SCLevelsHistory* levelsHistory = self->_levelsHistory;
    
    UpdateHistoryActionFromRequest pushLevelActionFromRequest = ^UpdateHistoryActionBlock( SCReadItemsRequest* request )
    {
        UpdateHistoryActionBlock pushLevelAction = ^void(void)
        {
            [ levelsHistory pushRequest: request
                                forItem: item ];
        };
        
        return [ pushLevelAction copy ];
    };

    [ self loadLevelForItem: item
                  callbacks: callbacks
              ignoringCache: shouldIgnoreCache
     pushLevelActionBuilder: pushLevelActionFromRequest ];
}

-(void)reloadCurrentLevelNotifyingCallbacks:( SCItemsFileManagerCallbacks* )callbacks
                              ignoringCache:( BOOL )shouldIgnoreCache
{
    SCLevelsHistory* levelsHistory = self->_levelsHistory;
    SCItem* item = [ levelsHistory lastItem ];
    NSParameterAssert( nil != item );
    
    UpdateHistoryActionFromRequest idleActionFromRequest = ^UpdateHistoryActionBlock( SCReadItemsRequest* request )
    {
        UpdateHistoryActionBlock idleAction = ^void(void)
        {
            // idle
        };
        
        return [ idleAction copy ];
    };
    
    [ self loadLevelForItem: item
                  callbacks: callbacks
              ignoringCache: shouldIgnoreCache
     pushLevelActionBuilder: idleActionFromRequest ];
}

-(void)goToLevelUpNotifyingCallbacks:( SCItemsFileManagerCallbacks* )callbacks
{
    SCReadItemsRequest* request = [ self->_levelsHistory levelUpRequest ];
    SCItem* levelUpParentItem     = [ self->_levelsHistory levelUpParentItem ];
    
    NSParameterAssert( nil != request           );
    NSParameterAssert( nil != levelUpParentItem );
    
    // set cache flag to zero
    request.flags &= SCReadItemRequestReadFieldsValues;
    
    
    SCLevelsHistory* levelsHistory = self->_levelsHistory;
    OnLevelLoadedBlock originalCompletion = [ callbacks.onLevelLoadedBlock copy ];
    UpdateHistoryActionBlock popLevelAction = ^void(void)
    {
        [ levelsHistory popRequest ];
    };
    
    SCDidFinishAsyncOperationHandler completionHook = [ self hookLevelCompletion: originalCompletion
                                                               byUpdatingHistory: popLevelAction
                                                               parentItemOfLevel: levelUpParentItem ];
    
    
    SCExtendedAsyncOp loader = [ self levelLoaderFromRequest: request ];
    self.cancelLoaderBlock = loader(
        callbacks.onLevelProgressBlock,
        nil,
        completionHook );
}


#pragma mark -
#pragma mark loadLevelForItem
-(void)loadLevelForItem:( SCItem* )item
              callbacks:( SCItemsFileManagerCallbacks* )callbacks
          ignoringCache:( BOOL )shouldIgnoreCache
 pushLevelActionBuilder:( UpdateHistoryActionFromRequest )actionFromRequest
{
    NSParameterAssert( nil != callbacks.onLevelLoadedBlock );
    
    SCReadItemsRequest* request = [ self buildLevelRequestForItem: item
                                                      ignoringCache: shouldIgnoreCache ];
    SCExtendedAsyncOp loader = [ self levelLoaderFromRequest: request ];
    
    
    UpdateHistoryActionBlock pushLevelAction = actionFromRequest( request );
    OnLevelLoadedBlock originalCompletion = [ callbacks.onLevelLoadedBlock copy ];

    SCDidFinishAsyncOperationHandler completionHook = [ self hookLevelCompletion: originalCompletion
                                                               byUpdatingHistory: pushLevelAction
                                                               parentItemOfLevel: item ];
    
    self.cancelLoaderBlock = loader(
                                    callbacks.onLevelProgressBlock,
                                    nil,
                                    completionHook );
}

-(SCReadItemsRequest*)buildLevelRequestForItem:( SCItem* )item
                                   ignoringCache:( BOOL )shouldIgnoreCache
{
    NSParameterAssert( nil != item );
    
    NSParameterAssert( nil != self->_apiSession );
    NSParameterAssert( nil != self->_nextLevelRequestBuilder );

    SCReadItemsRequest* request = [ self->_nextLevelRequestBuilder itemsBrowser: self
                                                          levelDownRequestForItem: item ];

    NSParameterAssert( nil != request );
    
    if ( shouldIgnoreCache )
    {
        request.flags |= SCReadItemRequestIngnoreCache;
    }

    return request;
}

-(void)setCancelLoaderBlock:( SCCancelAsyncOperation )cancelLoaderBlock
{
    if ( nil != self->_cancelLoaderBlock )
    {
        self->_cancelLoaderBlock( YES );
    }
    
    self->_cancelLoaderBlock = cancelLoaderBlock;
}

#pragma mark -
#pragma mark goToLevelUpNotifyingCallbacks
-(SCDidFinishAsyncOperationHandler)hookLevelCompletion:( OnLevelLoadedBlock )originalCompletion
                                     byUpdatingHistory:( UpdateHistoryActionBlock )actionBlock
                                     parentItemOfLevel:( SCItem* )item
{
    __weak SCItemsFileManager* weakSelf = self;
    
    SCDidFinishAsyncOperationHandler completionHook = ^void( NSArray* loadedItems, NSError *error )
    {
        SCLevelResponse* response = nil;
        
        if ( nil != loadedItems )
        {
            NSParameterAssert( nil == error );
            actionBlock();
            
            BOOL shouldAddFakeItem = [ weakSelf.levelsHistory isLevelUpAvailable ];
            if ( shouldAddFakeItem )
            {
                SCLevelUpItem* fakeLevelUp = [ SCLevelUpItem new ];
                loadedItems = [ @[ fakeLevelUp ] arrayByAddingObjectsFromArray: loadedItems ];
            }
            
            response = [ [ SCLevelResponse alloc ] initWithItem: item
                                              levelContentItems: loadedItems ];
        }
        
        originalCompletion( response, error );
    };
    
    return [ completionHook copy ];
}


// @adk : used for mocking in unit tests. Rename with care.
// Do not inline
-(SCExtendedAsyncOp)levelLoaderFromRequest:( SCReadItemsRequest* )request
{
    return [ self->_apiSession readItemsOperationWithRequest: request ];
}

@end
