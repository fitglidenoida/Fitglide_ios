//
//  WorkoutMapView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 21/06/25.
//

import SwiftUI
import MapKit

struct WorkoutMapView: View {
    let route: [[String: Float]]
    let workoutType: String
    @Environment(\.colorScheme) var colorScheme
    @State private var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var routeCoordinates: [CLLocationCoordinate2D] = []
    
    private var colors: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Map Header
            HStack {
                Image(systemName: "map.fill")
                    .font(.title2)
                    .foregroundColor(colors.primary)
                
                Text("\(workoutType) Route")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
                
                Text("\(routeCoordinates.count) points")
                    .font(FitGlideTheme.caption)
                    .foregroundColor(colors.onSurfaceVariant)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            // Map View
            if !routeCoordinates.isEmpty {
                Map(position: .constant(.region(region))) {
                    // Add start annotation
                    if let startCoordinate = routeCoordinates.first {
                        Annotation("Start", coordinate: startCoordinate) {
                            Image(systemName: "flag.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                        }
                    }
                    
                    // Add end annotation
                    if let endCoordinate = routeCoordinates.last, routeCoordinates.count > 1 {
                        Annotation("End", coordinate: endCoordinate) {
                            Image(systemName: "flag.checkered")
                                .foregroundColor(.red)
                                .font(.title2)
                        }
                    }
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)
            } else {
                // Placeholder when no route data
                RoundedRectangle(cornerRadius: 16)
                    .fill(colors.surfaceVariant)
                    .frame(height: 200)
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "map")
                                .font(.system(size: 40))
                                .foregroundColor(colors.onSurfaceVariant)
                            Text("No route data available")
                                .font(FitGlideTheme.bodyMedium)
                                .foregroundColor(colors.onSurfaceVariant)
                        }
                    )
                    .padding(.horizontal, 20)
            }
        }
        .onAppear {
            processRouteData()
        }
    }
    
    private func processRouteData() {
        routeCoordinates = route.compactMap { coordinateDict in
            guard let latitude = coordinateDict["latitude"] ?? coordinateDict["lat"],
                  let longitude = coordinateDict["longitude"] ?? coordinateDict["lng"] else {
                return nil
            }
            return CLLocationCoordinate2D(latitude: Double(latitude), longitude: Double(longitude))
        }
        
        if let firstCoordinate = routeCoordinates.first {
            region = MKCoordinateRegion(
                center: firstCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }
    

}



// MARK: - Enhanced Map View with Polyline
struct EnhancedWorkoutMapView: View {
    let route: [[String: Float]]
    let workoutType: String
    @Environment(\.colorScheme) var colorScheme
    @State private var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var routeCoordinates: [CLLocationCoordinate2D] = []
    
    private var colors: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Map Header
            HStack {
                Image(systemName: "map.fill")
                    .font(.title2)
                    .foregroundColor(colors.primary)
                
                Text("\(workoutType) Route")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
                
                if !routeCoordinates.isEmpty {
                    Text("\(routeCoordinates.count) points")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(colors.onSurfaceVariant)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            // Enhanced Map View
            if !routeCoordinates.isEmpty {
                MapViewRepresentable(
                    region: $region,
                    routeCoordinates: routeCoordinates,
                    primaryColor: colors.primary
                )
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)
            } else {
                // Placeholder when no route data
                RoundedRectangle(cornerRadius: 16)
                    .fill(colors.surfaceVariant)
                    .frame(height: 200)
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "map")
                                .font(.system(size: 40))
                                .foregroundColor(colors.onSurfaceVariant)
                            Text("No route data available")
                                .font(FitGlideTheme.bodyMedium)
                                .foregroundColor(colors.onSurfaceVariant)
                        }
                    )
                    .padding(.horizontal, 20)
            }
        }
        .onAppear {
            processRouteData()
        }
    }
    
    private func processRouteData() {
        routeCoordinates = route.compactMap { coordinateDict in
            guard let latitude = coordinateDict["latitude"] ?? coordinateDict["lat"],
                  let longitude = coordinateDict["longitude"] ?? coordinateDict["lng"] else {
                return nil
            }
            return CLLocationCoordinate2D(latitude: Double(latitude), longitude: Double(longitude))
        }
        
        if let firstCoordinate = routeCoordinates.first {
            region = MKCoordinateRegion(
                center: firstCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }
}

// MARK: - UIKit Map View Wrapper
struct MapViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let routeCoordinates: [CLLocationCoordinate2D]
    let primaryColor: Color
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = false
        mapView.showsCompass = true
        mapView.showsScale = true
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.setRegion(region, animated: true)
        
        // Clear existing overlays and annotations
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
        
        // Add route polyline
        if routeCoordinates.count > 1 {
            let polyline = MKPolyline(coordinates: routeCoordinates, count: routeCoordinates.count)
            mapView.addOverlay(polyline)
        }
        
        // Add start and end annotations
        if let startCoordinate = routeCoordinates.first {
            let startAnnotation = MKPointAnnotation()
            startAnnotation.coordinate = startCoordinate
            startAnnotation.title = "Start"
            mapView.addAnnotation(startAnnotation)
        }
        
        if let endCoordinate = routeCoordinates.last, routeCoordinates.count > 1 {
            let endAnnotation = MKPointAnnotation()
            endAnnotation.coordinate = endCoordinate
            endAnnotation.title = "End"
            mapView.addAnnotation(endAnnotation)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable
        
        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor(parent.primaryColor)
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil
            }
            
            let identifier = "RouteAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            // Customize annotation appearance
            if annotation.title == "Start" {
                annotationView?.image = UIImage(systemName: "flag.fill")?.withTintColor(.green, renderingMode: .alwaysOriginal)
            } else if annotation.title == "End" {
                annotationView?.image = UIImage(systemName: "flag.checkered")?.withTintColor(.red, renderingMode: .alwaysOriginal)
            }
            
            return annotationView
        }
    }
}

#Preview {
    let sampleRoute: [[String: Float]] = [
        ["latitude": 37.7749, "longitude": -122.4194],
        ["latitude": 37.7849, "longitude": -122.4094],
        ["latitude": 37.7949, "longitude": -122.3994]
    ]
    
    return EnhancedWorkoutMapView(route: sampleRoute, workoutType: "Running")
        .preferredColorScheme(.dark)
}

