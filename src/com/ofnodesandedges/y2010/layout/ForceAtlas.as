/**
 *
 * SiGMa, the Simple Graph Mapper
 * Copyright (C) 2010, Alexis Jacomy
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

package com.ofnodesandedges.y2010.layout{
	
	import com.ofnodesandedges.y2010.graphics.GraphGraphics;
	import com.ofnodesandedges.y2010.graphics.NodeGraphics;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	
	public class ForceAtlas extends Layout{
		
		// Force vector parameters:
		private var _inertia:Number;
		private var _repulsionStrength:Number;
		private var _attractionStrength:Number;
		private var _maxDisplacement:Number;
		private var _freezeStrength:Number;
		private var _freezeInertia:Number;
		private var _nodeOverlap:Boolean;
		private var _gravity:Number;
		private var _speed:Number;
		private var _cooling:Number;
		
		public function ForceAtlas(){}

		public override function init(graphGraphics:GraphGraphics):void{
			_stepsNumber = 0;
			_autoStop = false;
			
			// Force vector parameters:
			_inertia = 0.1;
			_attractionStrength = 0.1;
			_repulsionStrength = 1;
			_maxDisplacement = 500;
			_freezeStrength = 10;
			_freezeInertia = 0.5;
			_gravity = 0;
			_speed = 500;
			_cooling = 1;
			_nodeOverlap = true;
			
			_graph = graphGraphics;
			
			var k:int, i:int, node:NodeGraphics;
			k = _graph.nodes.length;
			
			// Init dx dy
			for(i=0;i<k;i++){
				node = _graph.nodes[i];
				node.dx = 0;
				node.dy = 0;
				node.old_dx = 0;
				node.old_dy = 0;
			}
		}
		
		public override function stepHandler(e:Event):void{
			computeForceVectorOneStep();
			_stepsNumber = _stepsNumber+1;
			
			var maxCooling:Number = 10;
			var coeff:Number = 0.995;
			var stepsBeforeCooling:int = 180;
			
			if(_stepsNumber>stepsBeforeCooling){
				_cooling = maxCooling-(maxCooling-_cooling)*coeff;
			}
			
			dispatchEvent(new Event(ONE_STEP));
		}
		
		private function computeForceVectorOneStep(opt:Object = null):void{
			var i:int, j:int, k:int, l:int = _graph.nodes.length;
			var n:NodeGraphics, n1:NodeGraphics, n2:NodeGraphics;
			var dist:Number, xDist:Number, yDist:Number, newDist:Number;
			
			for (i=0;i<l;i++) {
				n = _graph.nodes[i];
				n.old_dx = n.dx;
				n.old_dy = n.dy;
				n.dx *= _inertia;
				n.dy *= _inertia;
			}
			
			for (i=0;i<l-1;i++) {
				// repulsion
				n1 = _graph.nodes[i];
				
				for (j=i+1;j<l;j++) {
					n2 = _graph.nodes[j];
					
					fcBiRepulsor_noCollide(n1, n2, 2 * _repulsionStrength * (1 + n1.getOutNeighborsCount()) * (1 + n2.getOutNeighborsCount()));
				}
				
				// attraction
				for each(n2 in n1.outNeighbors) {
					
					// REPETITION POSSIBLY A PROBLEM
					fcBiAttractor_noCollide(n1, n2, _attractionStrength / (1 + n1.getOutNeighborsCount()));
				}
			}
			
			//attraction from the last node:
			n1 = _graph.nodes[l-1];
			for each(n2 in n1.outNeighbors) {
				
				// REPETITION POSSIBLY A PROBLEM
				fcBiAttractor_noCollide(n1, n2, _attractionStrength / (1 + n1.getOutNeighborsCount()));
			}
			
			// gravity
			for (i=0;i<l;i++) {
				n = _graph.nodes[i];
				
				n.dx -= _gravity * n.x;
				n.dy -= _gravity * n.y;
				
				// speed
				n = _graph.nodes[i];
				
				n.dx *= _speed;
				n.dy *= _speed;

				// apply forces
				n = _graph.nodes[i];
				
				var d2:Number = 0.0001 + Math.sqrt(n.dx * n.dx + n.dy * n.dy);
				var ratio:Number;
				
				n.freeze = _freezeInertia*n.freeze+(1-_freezeInertia)*_freezeStrength*Math.pow((n.old_dx-n.dx)*(n.old_dx-n.dx) + (n.old_dy-n.dy)*(n.old_dy-n.dy),1/4);
				ratio = Math.min(1/(1+n.freeze), _maxDisplacement/d2);
				
				n.dx *= ratio / _cooling;
				n.dy *= ratio / _cooling;
				
				if(!n.stopped){
					n.x = n.x + n.dx;
					n.y = n.y + n.dy;
				}
			}
			
			// rotation
			//rotation(0.1);
		}
		
		private function fcBiRepulsor_noCollide(N1:NodeGraphics, N2:NodeGraphics, c:Number):void{
			var xDist:Number = N1.x - N2.x;	// distance en x entre les deux noeuds
			var yDist:Number = N1.y - N2.y;
			var dist:Number = Math.sqrt(xDist * xDist + yDist * yDist) - N1.size - N2.size;	// distance (from the border of each node)
			
			if(_nodeOverlap == true){
				if (dist > 0) {
					N1.dx += xDist / (dist * dist) * c;
					N1.dy += yDist / (dist * dist) * c;
					
					N2.dx -= xDist / (dist * dist) * c;
					N2.dy -= yDist / (dist * dist) * c;
				} else if (dist != 0) {
					N1.dx += xDist / (N1.size + N2.size) * c;
					N1.dy += yDist / (N1.size + N2.size) * c;
					
					N2.dx -= xDist / (N1.size + N2.size) * c;
					N2.dy -= yDist / (N1.size + N2.size) * c;
				}
			}else{
				if (dist > 0) {
					dist += N1.size + N2.size;
					
					N1.dx += xDist / (dist * dist) * c;
					N1.dy += yDist / (dist * dist) * c;
					
					N2.dx -= xDist / (dist * dist) * c;
					N2.dy -= yDist / (dist * dist) * c;
				}
			}
		}
		
		private function fcBiAttractor_noCollide(N1:NodeGraphics, N2:NodeGraphics, c:Number):void{
			var xDist:Number = N1.x - N2.x;	// distance en x entre les deux noeuds
			var yDist:Number = N1.y - N2.y;
			var dist:Number = Math.sqrt(xDist * xDist + yDist * yDist) - N1.size - N2.size;	// distance (from the border of each node)
			
			if (dist > 0) {
				N1.dx -= xDist * c;
				N1.dy -= yDist * c;
				
				N2.dx += xDist * c;
				N2.dy += yDist * c;
			}
		}
		
		private function rotation(degree_angle:Number):void{
			var i:int,l:int = _graph.nodes.length;
			var xTemp:Number,yTemp:Number,radians:Number;
			var n:NodeGraphics;
			
			for (i=0;i<l;i++) {
				n = _graph.nodes[i];
				radians = Math.PI*degree_angle/180;
				
				xTemp = n.x*Math.cos(radians) - n.y*Math.sin(radians);
				yTemp = n.x*Math.sin(radians) + n.y*Math.cos(radians);
				
				n.x = xTemp;
				n.y = yTemp;
				
				xTemp = n.dx*Math.cos(radians) - n.dy*Math.sin(radians);
				yTemp = n.dx*Math.sin(radians) + n.dy*Math.cos(radians);
				
				n.dx = xTemp;
				n.dy = yTemp;
				
				n.x *= 0.8;
				n.y *= 0.8;
			}
		}
	}
}