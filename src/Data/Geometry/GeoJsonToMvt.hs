{-# LANGUAGE FlexibleContexts #-}

module Data.Geometry.GeoJsonToMvt where

import qualified Control.Monad.ST                as ST
import qualified Data.Aeson                      as A
import qualified Data.Foldable                   as F (foldMap)
import qualified Data.Geospatial                 as DG
import qualified Data.LinearRing                 as DG
import qualified Data.LineString                 as DG
import qualified Data.List                       as DL
import qualified Data.STRef                      as ST
import qualified Data.Vector                     as DV
import qualified Geography.VectorTile.Geometry   as VG

import           Data.Geometry.SphericalMercator
import           Data.Geometry.Types.MvtFeatures
import           Data.Geometry.Types.Types

-- Lib

geoJsonFeaturesToMvtFeatures :: ZoomConfig -> [DG.GeoFeature A.Value] -> ST.ST s MvtFeatures
geoJsonFeaturesToMvtFeatures zConfig features = do
  ops <- ST.newSTRef 0
  F.foldMap (convertFeature zConfig ops) features

-- Feature

convertFeature :: ZoomConfig -> ST.STRef s Int -> DG.GeoFeature A.Value -> ST.ST s MvtFeatures
convertFeature zConfig ops (DG.GeoFeature _ geom props mfid) = do
  fid <- convertId mfid ops
  pure $ convertGeometry zConfig fid props geom

-- Geometry

convertGeometry :: ZoomConfig -> Int -> A.Value -> DG.GeospatialGeometry -> MvtFeatures
convertGeometry zConfig fid props geom =
  case geom of
    DG.NoGeometry     -> mempty
    DG.Point g        -> mkPoint fid props . convertPoint zConfig $ g
    DG.MultiPoint g   -> mkPoint fid props . convertMultiPoint zConfig $ g
    DG.Line g         -> mkLineString fid props . convertLineString zConfig $ g
    DG.MultiLine g    -> mkLineString fid props . convertMultiLineString zConfig $ g
    DG.Polygon g      -> mkPolygon fid props . convertPolygon zConfig $ g
    DG.MultiPolygon g -> mkPolygon fid props . convertMultiPolygon zConfig $ g
    DG.Collection gs  -> F.foldMap (convertGeometry zConfig fid props) gs

-- FeatureID

readFeatureID :: Maybe DG.FeatureID -> Maybe Int
readFeatureID mfid =
  case mfid of
    Just (DG.FeatureIDNumber x) -> Just x
    _                           -> Nothing

convertId :: Maybe DG.FeatureID -> ST.STRef s Int -> ST.ST s Int
convertId mfid ops =
  case readFeatureID mfid of
    Just val -> pure val
    Nothing  -> do
      ST.modifySTRef ops (+1)
      ST.readSTRef ops

-- Points

convertPoint :: ZoomConfig -> DG.GeoPoint -> DV.Vector VG.Point
convertPoint zConfig = coordsToPoints zConfig . DG._unGeoPoint

convertMultiPoint :: ZoomConfig -> DG.GeoMultiPoint -> DV.Vector VG.Point
convertMultiPoint zConfig = F.foldMap (convertPoint zConfig) . DG.splitGeoMultiPoint

-- Lines

convertLineString :: ZoomConfig -> DG.GeoLine -> DV.Vector VG.LineString
convertLineString zConfig =
    DV.singleton .
    VG.LineString .
    DV.convert .
    F.foldMap (coordsToPoints zConfig) .
    DG.fromLineString .
    DG._unGeoLine

convertMultiLineString :: ZoomConfig -> DG.GeoMultiLine -> DV.Vector VG.LineString
convertMultiLineString zConfig = F.foldMap (convertLineString zConfig) . DG.splitGeoMultiLine

-- Polygons

convertPolygon :: ZoomConfig -> DG.GeoPolygon -> DV.Vector VG.Polygon
convertPolygon zConfig poly = DV.singleton $
  case DG._unGeoPolygon poly of
    []    -> VG.Polygon mempty mempty
    (h:t) ->
      case t of
        []   -> mkPoly h
        rest -> VG.Polygon (mkPolyPoints h) (mkPolys rest)
  where
    mkPolyPoints = DV.convert . F.foldMap (coordsToPoints zConfig) . DG.fromLinearRing
    mkPoly lring = VG.Polygon (mkPolyPoints lring) mempty
    mkPolys      = DL.foldl' (\acc lring -> DV.cons (mkPoly lring) acc) mempty

convertMultiPolygon :: ZoomConfig -> DG.GeoMultiPolygon -> DV.Vector VG.Polygon
convertMultiPolygon zConfig = F.foldMap (convertPolygon zConfig) . DG.splitGeoMultiPolygon

-- Helpers

createLines :: [a] -> DV.Vector (a, a)
createLines = DV.fromList . (zip <*> tail)

coordsToPoints :: ZoomConfig -> [Double] -> DV.Vector VG.Point
coordsToPoints _ []        = mempty
coordsToPoints _ [_]       = mempty
coordsToPoints (ZoomConfig ext q bb) x = fmap (latLonToXYInTile ext q bb . uncurry LatLon) (createLines x)
