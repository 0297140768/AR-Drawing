import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    var selectedNode: SCNNode?
    var placedNodes: [SCNNode] = []
    var planeNodes: [SCNNode] = []
    
    @IBOutlet var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    
    enum ObjectPlacementMode {
        case freeform, plane, image
    }
    
    var objectMode: ObjectPlacementMode = .freeform {
        didSet {
            reloadCofiguration()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadCofiguration()
    }
    
    func reloadCofiguration() {
        configuration.detectionImages = (objectMode == .image) ? ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) : nil
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    @IBAction func changeObjectMode(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            objectMode = .freeform
        case 1:
            objectMode = .plane
        case 2:
            objectMode = .image
        default:
            break
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showOptions" {
            let optionsViewController = segue.destination as! OptionsContainerViewController
            optionsViewController.delegate = self
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        guard let node = selectedNode,
            let touch = touches.first else { return }
        
        switch objectMode {
        case .freeform:
            addNodeInFront(node)
        case .image:
            break
        case .plane:
            break
        }
    }
    
    func addNodeInFront(_ node: SCNNode) {
        guard let currentFrame = sceneView.session.currentFrame else { return }
        var translation  = matrix_identity_float4x4
        translation.columns.3.z = -0.2
        //translation =  simd_float4x4(SCNMatrix4Rotate(SCNMatrix4(translation), GLKMathDegreesToRadians(90), 0, 0, 1.0))
        let rotation = simd_float4x4(SCNMatrix4MakeRotation(GLKMathDegreesToRadians(90), 0, 0, 1))
        translation = matrix_multiply(translation, rotation)
        node.simdTransform = matrix_multiply(currentFrame.camera.transform, translation)
        
        addNodeToSceneRoot(node)
    }
    
    func addNodeToSceneRoot(_ node: SCNNode) {
        let cloneNode = node.clone()
        sceneView.scene.rootNode.addChildNode(cloneNode)
        placedNodes.append(cloneNode)
    }
    
    func addNode(_ node: SCNNode, toImageUsingParentNode parentNode: SCNNode) {
        let cloneNode = node.clone()
        parentNode.addChildNode(cloneNode)
        placedNodes.append(cloneNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        if let imageAnchor = anchor as? ARImageAnchor {
            nodeAdded(node, anchor: imageAnchor)
        } else if let planeAnchor = anchor as? ARPlaneAnchor {
            nodeAdded(node, anchor: planeAnchor)
        }
    }
    
    func nodeAdded(_ node: SCNNode, anchor: ARImageAnchor) {
        if let selectedNode = selectedNode {
            addNode(node, toImageUsingParentNode: selectedNode)
        }
    }
    
    func nodeAdded(_ node: SCNNode, anchor: ARPlaneAnchor) {
        
    }
}

extension ViewController: OptionsViewControllerDelegate {
    
    func objectSelected(node: SCNNode) {
        dismiss(animated: true, completion: nil)
        selectedNode = node
    }
    
    func togglePlaneVisualization() {
        dismiss(animated: true, completion: nil)
    }
    
    func undoLastObject() {
        
    }
    
    func resetScene() {
        dismiss(animated: true, completion: nil)
    }
}
