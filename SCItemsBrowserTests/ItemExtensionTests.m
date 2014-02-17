#import <XCTest/XCTest.h>

#import <SCItemsBrowser/SCItemsBrowser.h>

#import "SCItem+Media.h"
#import <SitecoreMobileSDK/SitecoreMobileSDK.h>

#import <MobileSDK-Private/SCItemRecord_Source.h>
#import <MobileSDK-Private/SCItem+PrivateMethods.h>


#import "ImageLoaderBuilderHook.h"

@interface ItemExtensionTests : XCTestCase
@end

@implementation ItemExtensionTests
{
    SCExtendedApiContext* _context          ;
    SCApiContext        * _legacyContext    ;
    
    SCItemSourcePOD* _recordSource;
    
    SCItem      * _rootItem                 ;
    SCItemRecord* _rootRecord               ;
    
    SCItem      * _mediaImageItem           ;
    SCItemRecord* _mediaImageRecord         ;
    
    SCItem      * _mediaItemOutsideLibrary  ;
    SCItemRecord* _mediaRecordOutsideLibrary;
    
    SCItem      * _folderItemInsideLibrary  ;
    SCItemRecord* _folderRecordInsideLibrary;
}

-(void)setUp
{
    [ super setUp ];
    
    SCItemRecord* newRecord  = nil;
    
    self->_legacyContext = [ SCApiContext contextWithHost: @"stub-host.net" ];
    self->_context = self->_legacyContext.extendedApiContext;

    SCItemSourcePOD* recordSource = [ SCItemSourcePOD new ];
    {
        recordSource.database = @"master"         ;
        recordSource.language = @"ru"             ;
        recordSource.site     = @"/sitecore/shell";
        recordSource.itemVersion = @"100500";
    }
    self->_recordSource = recordSource;
    
    newRecord = [ SCItemRecord new ];
    {
        newRecord.displayName  = @"хомяк"                 ;
        newRecord.path         = @"/sitecore/content/home";
        newRecord.itemTemplate = @"common/folder"         ;
        
        newRecord.apiContext     = self->_context      ;
        newRecord.mainApiContext = self->_legacyContext;
        
        newRecord.itemSource = recordSource;
    }
    self->_rootRecord = newRecord;
    self->_rootItem   = [ [ SCItem alloc ] initWithRecord: self->_rootRecord
                                               apiContext: self->_context ];
    
    
    newRecord = [ SCItemRecord new ];
    {
        newRecord.displayName  = @"grumpy cat.jpg"                      ;
        newRecord.path         = @"/sitecore/media library/grumpy cat"  ;
        newRecord.itemTemplate = @"system/media/unversioned/image"      ;
        
        newRecord.apiContext     = self->_context      ;
        newRecord.mainApiContext = self->_legacyContext;
        
        newRecord.itemSource = recordSource;
    }
    self->_mediaImageRecord = newRecord;
    self->_mediaImageItem   = [ [ SCItem alloc ] initWithRecord: self->_mediaImageRecord
                                                     apiContext: self->_context ];

    
    newRecord = [ SCItemRecord new ];
    {
        newRecord.displayName  = @"facepalm.jpg"                       ;
        newRecord.path         = @"/sitecore/content/home/facepalm.jpg";
        newRecord.itemTemplate = @"system/media/unversioned/image"     ;
        
        newRecord.apiContext     = self->_context      ;
        newRecord.mainApiContext = self->_legacyContext;
        
        newRecord.itemSource = recordSource;
    }
    self->_mediaRecordOutsideLibrary = newRecord;
    self->_mediaItemOutsideLibrary   =
    [ [ SCItem alloc ] initWithRecord: self->_mediaRecordOutsideLibrary
                           apiContext: self->_context ];
    
    
    newRecord = [ SCItemRecord new ];
    {
        newRecord.displayName  = @"logo logo icons"                   ;
        newRecord.path         = @"/sitecore/media library/logo icons";
        newRecord.itemTemplate = @"COMMON/FOLDER"                     ;
        
        newRecord.apiContext     = self->_context      ;
        newRecord.mainApiContext = self->_legacyContext;
        
        newRecord.itemSource = recordSource;        
    }
    self->_folderRecordInsideLibrary = newRecord;
    self->_folderItemInsideLibrary   =
    [ [ SCItem alloc ] initWithRecord: self->_folderRecordInsideLibrary
                           apiContext: self->_context ];
    
}

-(void)tearDown
{
    self->_rootItem                   = nil;
    self->_rootRecord                 = nil;
    self->_mediaImageItem             = nil;
    self->_mediaImageRecord           = nil;
    self->_mediaItemOutsideLibrary    = nil;
    self->_mediaRecordOutsideLibrary  = nil;
    self->_folderItemInsideLibrary    = nil;
    self->_folderRecordInsideLibrary  = nil;
    
    [ super tearDown ];
}

-(void)testMediaItemDetection
{
    XCTAssertFalse( [ self->_rootItem                isMediaItem ], @"_rootItem       misamatch"          );
    XCTAssertTrue ( [ self->_mediaImageItem          isMediaItem ], @"_mediaImageItem misamatch"          );
    XCTAssertFalse( [ self->_mediaItemOutsideLibrary isMediaItem ], @"_mediaItemOutsideLibrary misamatch" );
    XCTAssertTrue ( [ self->_folderItemInsideLibrary isMediaItem ], @"_folderItemInsideLibrary misamatch" );
}

-(void)testImageDetection
{
    XCTAssertFalse( [ self->_rootItem                isImage ], @"_rootItem       misamatch"          );
    XCTAssertTrue ( [ self->_mediaImageItem          isImage ], @"_mediaImageItem misamatch"          );
    XCTAssertTrue ( [ self->_mediaItemOutsideLibrary isImage ], @"_mediaItemOutsideLibrary misamatch" );
    XCTAssertFalse( [ self->_folderItemInsideLibrary isImage ], @"_folderItemInsideLibrary misamatch" );
}

-(void)testMediaImageDetection
{
    XCTAssertFalse( [ self->_rootItem                isMediaImage ], @"_rootItem       misamatch"          );
    XCTAssertTrue ( [ self->_mediaImageItem          isMediaImage ], @"_mediaImageItem misamatch"          );
    XCTAssertFalse( [ self->_mediaItemOutsideLibrary isMediaImage ], @"_mediaItemOutsideLibrary misamatch" );
    XCTAssertFalse( [ self->_folderItemInsideLibrary isMediaImage ], @"_folderItemInsideLibrary misamatch" );
}

-(void)testFolderDetection
{
    XCTAssertTrue ( [ self->_rootItem                isFolder ], @"_rootItem       misamatch"          );
    XCTAssertFalse( [ self->_mediaImageItem          isFolder ], @"_mediaImageItem misamatch"          );
    XCTAssertFalse( [ self->_mediaItemOutsideLibrary isFolder ], @"_mediaItemOutsideLibrary misamatch" );
    XCTAssertTrue ( [ self->_folderItemInsideLibrary isFolder ], @"_folderItemInsideLibrary misamatch" );
}

-(void)testItemsOutsideMediaLibraryHaveNoMediaPath
{
    XCTAssertNil   ( [ self->_rootItem                mediaPath ], @"_rootItem       misamatch"          );
    XCTAssertNotNil( [ self->_mediaImageItem          mediaPath ], @"_mediaImageItem misamatch"          );
    XCTAssertNil   ( [ self->_mediaItemOutsideLibrary mediaPath ], @"_mediaItemOutsideLibrary misamatch" );
    XCTAssertNotNil( [ self->_folderItemInsideLibrary mediaPath ], @"_folderItemInsideLibrary misamatch" );
}

-(void)testItemsOutsideMediaLibraryHaveNoMediaLoader
{
    SCFieldImageParams* resizingOptions = [ SCFieldImageParams new ];
    
    XCTAssertNil   ( [ self->_rootItem                mediaLoaderWithOptions: resizingOptions ], @"_rootItem       misamatch"          );
    XCTAssertNotNil( [ self->_mediaImageItem          mediaLoaderWithOptions: resizingOptions ], @"_mediaImageItem misamatch"          );
    XCTAssertNil   ( [ self->_mediaItemOutsideLibrary mediaLoaderWithOptions: resizingOptions ], @"_mediaItemOutsideLibrary misamatch" );
    XCTAssertNotNil( [ self->_folderItemInsideLibrary mediaLoaderWithOptions: resizingOptions ], @"_folderItemInsideLibrary misamatch" );
}

-(void)testItemsLoaderSetsItemSourceToResizingParams
{
    __block NSString          * actualMediaPath   = nil;
    __block SCFieldImageParams* actualImageParams = nil;
    
    
    ImageLoaderBuilder hookImpl = ^SCExtendedAsyncOp( SCExtendedApiContext* blockSelf, NSString* mediaPath, SCFieldImageParams* options )
    {
        // runtime swaps args
        
        actualMediaPath   = mediaPath;
        actualImageParams = options;

        // will be ignored
        return nil;
    };
    ImageLoaderBuilderHook* hook =
    [ [ ImageLoaderBuilderHook alloc ] initWithHookImpl: hookImpl ];
    

    [ hook enableHook ];
    {
        [ self->_mediaImageItem mediaLoaderWithOptions: nil ];
    }
    [ hook disableHook ];
    
    XCTAssertNotNil( actualMediaPath, @"media path must not be nil" );
    XCTAssertNotNil( actualImageParams, @"options must not be nil" );
    
    XCTAssertEqualObjects( @"/grumpy cat", actualMediaPath, @"media path mismatch" );
    
    XCTAssertEqualObjects( actualImageParams.database, self->_recordSource.database, @"database mismatch" );
    XCTAssertEqualObjects( actualImageParams.language, self->_recordSource.language, @"language mismatch" );
    XCTAssertEqualObjects( actualImageParams.version, self->_recordSource.itemVersion, @"itemVersion mismatch" );
}

@end
